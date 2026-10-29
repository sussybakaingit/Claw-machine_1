#!/usr/bin/env python3
"""
Hand Tracker Sidecar for Godot 3D Claw Machine
Tracks a single hand via webcam using MediaPipe and sends UDP JSON packets to Godot.
"""

import sys
import time
import json
import math
import socket

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 4242
    show_debug_window = "--debug" in sys.argv
    
    try:
        import cv2
    except ImportError:
        print("[HandTracker ERROR] cv2 (opencv-python) is not installed. Please run: pip install -r requirements.txt", file=sys.stderr)
        sys.exit(1)
        
    try:
        import mediapipe as mp
    except ImportError:
        print("[HandTracker ERROR] mediapipe is not installed. Please run: pip install -r requirements.txt", file=sys.stderr)
        sys.exit(1)

    # Initialize UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    dest_addr = ("127.0.0.1", port)

    # Initialize MediaPipe Hands
    mp_hands = mp.solutions.hands
    mp_drawing = mp.solutions.drawing_utils
    hands = mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=1,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    )

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print(f"[HandTracker ERROR] Could not open webcam index 0.", file=sys.stderr)
        sys.exit(2)

    # Request high framerate, standard resolution
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    cap.set(cv2.CAP_PROP_FPS, 30)

    print(f"[HandTracker] Streaming hand data to 127.0.0.1:{port}...", flush=True)

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                time.sleep(0.01)
                continue

            # Mirror horizontal for natural interaction
            frame = cv2.flip(frame, 1)
            h, w, _ = frame.shape

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = hands.process(rgb)

            packet = {
                "hand_detected": False,
                "timestamp": time.time()
            }

            if results.multi_hand_landmarks:
                landmarks = results.multi_hand_landmarks[0].landmark
                # Key landmarks:
                # 0: Wrist
                # 4: Thumb Tip
                # 5: Index MCP, 8: Index Tip
                # 9: Middle MCP, 12: Middle Tip
                # 13: Ring MCP, 16: Ring Tip
                # 17: Pinky MCP, 20: Pinky Tip
                wrist = landmarks[0]
                thumb_tip = landmarks[4]
                index_mcp = landmarks[5]
                index_tip = landmarks[8]
                middle_mcp = landmarks[9]
                middle_tip = landmarks[12]
                ring_tip = landmarks[16]
                pinky_mcp = landmarks[17]
                pinky_tip = landmarks[20]

                # Hand scale: distance between wrist and middle MCP
                hand_scale = math.hypot(middle_mcp.x - wrist.x, middle_mcp.y - wrist.y)
                if hand_scale < 0.01:
                    hand_scale = 0.01

                # Palm center (average of wrist, index_mcp, pinky_mcp)
                palm_x = (wrist.x + index_mcp.x + pinky_mcp.x) / 3.0
                palm_y = (wrist.y + index_mcp.y + pinky_mcp.y) / 3.0

                # Pinch distance: thumb_tip to index_tip normalized by hand scale
                pinch_raw = math.hypot(thumb_tip.x - index_tip.x, thumb_tip.y - index_tip.y)
                pinch_dist = pinch_raw / hand_scale

                # Fist amount: average distance from fingertip to palm center normalized
                d_idx = math.hypot(index_tip.x - palm_x, index_tip.y - palm_y) / hand_scale
                d_mid = math.hypot(middle_tip.x - palm_x, middle_tip.y - palm_y) / hand_scale
                d_rng = math.hypot(ring_tip.x - palm_x, ring_tip.y - palm_y) / hand_scale
                d_pnk = math.hypot(pinky_tip.x - palm_x, pinky_tip.y - palm_y) / hand_scale
                avg_dist = (d_idx + d_mid + d_rng + d_pnk) / 4.0
                
                # In open hand avg_dist is ~1.5 - 2.0; in tight fist avg_dist is ~0.4 - 0.7
                fist_amount = max(0.0, min(1.0, (1.6 - avg_dist) / 1.0))

                # Export landmark points
                pts = [{"x": round(lm.x, 3), "y": round(lm.y, 3)} for lm in landmarks]

                packet = {
                    "hand_detected": True,
                    "index_tip": {"x": round(index_tip.x, 3), "y": round(index_tip.y, 3)},
                    "palm_center": {"x": round(palm_x, 3), "y": round(palm_y, 3)},
                    "thumb_tip": {"x": round(thumb_tip.x, 3), "y": round(thumb_tip.y, 3)},
                    "pinch_distance": round(pinch_dist, 3),
                    "fist_amount": round(fist_amount, 3),
                    "landmarks": pts,
                    "timestamp": time.time()
                }

                if show_debug_window:
                    mp_drawing.draw_landmarks(frame, results.multi_hand_landmarks[0], mp_hands.HAND_CONNECTIONS)
                    cv2.putText(frame, f"Pinch: {pinch_dist:.2f} Fist: {fist_amount:.2f}", (10, 30),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

            # Send packet
            data_bytes = json.dumps(packet).encode("utf-8")
            sock.sendto(data_bytes, dest_addr)

            if show_debug_window:
                cv2.imshow("Hand Tracker Debug", frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

            time.sleep(0.016) # ~60 fps
    except KeyboardInterrupt:
        pass
    finally:
        cap.release()
        if show_debug_window:
            cv2.destroyAllWindows()
        sock.close()

if __name__ == "__main__":
    main()
