//
//  DraggableCameraPreview.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import ReplayKit
import AVFoundation

struct DraggableCameraPreview: View {
    @StateObject private var recordingManager = GameRecordingManager.shared
    @State private var dragOffset = CGSize.zero
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 80, y: 120)
    @State private var isVisible = false
    @State private var isExpanded = false
    @State private var animationScale: CGFloat = 0.8
    @State private var animationOpacity: Double = 0.0
    @State private var animationOffset = CGSize(width: 60, height: -60)
    @State private var animationRotation: Double = 15
    
    private let cornerRadius: CGFloat = 12
    private let borderWidth: CGFloat = 2
    
    private var previewSize: CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let width = screenWidth * 0.3
        let height = width * 1.25
        return CGSize(width: width, height: height)
    }
    
    private var currentSize: CGSize {
        previewSize
    }
    
    var body: some View {
        Group {
            if isVisible {
                CameraPreviewContainer()
                    .scaleEffect(animationScale)
                    .opacity(animationOpacity)
                    .offset(animationOffset)
                    .rotationEffect(.degrees(animationRotation))
                    .onAppear {
                        animateIn()
                    }
            }
        }
        .onChange(of: recordingManager.isRecording) { isRecording in
            if isRecording {
                isVisible = true
            } else {
                animateOut()
            }
        }
    }
    
    @ViewBuilder
    private func CameraPreviewContainer() -> some View {
        if let previewLayer = recordingManager.cameraPreviewLayer {
            ZStack {
                CameraPreviewView(previewLayer: previewLayer)
                .frame(width: currentSize.width, height: currentSize.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black, lineWidth: borderWidth)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
                .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: 1)
                .offset(x: dragOffset.width, y: dragOffset.height)
                .position(position)
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation }
                        .onEnded { value in
                            let newX = position.x + value.translation.width
                            let newY = position.y + value.translation.height
                            
                            let screenBounds = UIScreen.main.bounds
                            let clampedX = max(currentSize.width/2, min(screenBounds.width - currentSize.width/2, newX))
                            
                            let window = UIApplication.shared.connectedScenes
                                .compactMap { $0 as? UIWindowScene }
                                .flatMap { $0.windows }
                                .first { $0.isKeyWindow }
                            let safeAreaBottom: CGFloat = window?.safeAreaInsets.bottom ?? 0
                            let maxY = screenBounds.height - safeAreaBottom - currentSize.height
                            let clampedY = max(currentSize.height/2, min(maxY, newY))
                            
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                                position = CGPoint(x: clampedX, y: clampedY)
                                dragOffset = .zero
                            }
                        }
                )
                .scaleEffect(dragOffset != .zero ? 1.05 : 1.0)
                .rotationEffect(.degrees(dragOffset != .zero ? Double(dragOffset.width + dragOffset.height) / 40 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
            }
        }
    }
    
    private func animateIn() {
        animationScale = 0.8
        animationOpacity = 0.0
        animationOffset = CGSize(width: 60, height: -60)
        animationRotation = 15

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animationScale = 1.0
            animationOpacity = 1.0
            animationOffset = .zero
            animationRotation = 0
        }
    }
    
    private func animateOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationOpacity = 0.0
            animationScale = 0.8
            animationOffset = CGSize(width: 60, height: -60)
            animationRotation = -15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
            resetAnimation()
        }
    }

    private func resetAnimation() {
        animationOpacity = 0.0
        animationScale = 0.8
        animationOffset = CGSize(width: 60, height: -60)
        animationRotation = 15
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer = self.previewLayer
        view.previewLayer?.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        if uiView.previewLayer !== self.previewLayer {
            uiView.previewLayer = self.previewLayer
            uiView.previewLayer?.videoGravity = .resizeAspectFill
        }
    }
    
    class PreviewContainerView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer? {
            didSet {
                oldValue?.removeFromSuperlayer()
                
                if let newLayer = previewLayer {
                    newLayer.videoGravity = .resizeAspectFill
                    layer.addSublayer(newLayer)
                    setNeedsLayout()
                    layoutIfNeeded()
                }
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            UIView.performWithoutAnimation {
                previewLayer?.frame = self.bounds
            }
        }
    }
}
