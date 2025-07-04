//
//  ContentView.swift
//  HideDesktopIcons
//
//  Created by Tim on 29.06.25.
//

import SwiftUI
import DesktopHider

struct ContentView: View {
    let hider = DesktopHider.self
    @State var timer: Timer?
    @Binding var enabled: Bool
    var body: some View {
        VStack {
            Text("Desktop Hider")
                .font(.system(size: 25, weight: .bold))
            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(enabled ? .green : .red)
                Text(enabled ? "Icons Shown" : "Icons Hidden")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.gray)
            }
            Button("Toggle") {
                hider.setValue(!hider.readValue())
                enabled = hider.readValue()
            }
        }
        .frame(width: 225, height: 125)
        .onAppear {
            enabled = hider.readValue()
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
                enabled = hider.readValue()
            })
        }
    }
} 

struct PopupView: View {
    @Binding var bool: Bool?
    @State var opacity: CGFloat = 0
    var body: some View {
        Group {
            if let bool {
                HStack(spacing: 10) {
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(bool ? .green : .red)
                    VStack(alignment: .leading) {
                        Text("Desktop Icons Toggled").bold()
                        Text("Icons \(bool ? "Shown" : "Hidden")").foregroundStyle(.gray)
                    }
                }
                .frame(width: 200, height: 50)
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 7.5))
                .padding(2.5)
                .onAppear(perform: animateAppear)
                .padding(.horizontal)
            } else {
                Text("None")
                    .onAppear(perform: dismiss)
            }
        }
        .opacity(opacity)
    }
    @AppStorage("cancelDismiss") var cancelDismiss = false
    func animateAppear() {
        cancelDismiss = false
        opacity = 0
        withAnimation(.linear(duration: 0.5)) {
            opacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            animateDisappear()
        }
    }
    func animateDisappear() {
            withAnimation(.linear(duration: 0.5)) {
                opacity = 0
            }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if !cancelDismiss {
                dismiss()
            }
        })
    }
    func dismiss() {
        for window in NSApplication.shared.windows {
            if let id = window.identifier, id.rawValue.contains("popup") {
                print("Window contains Popup will be closed")
                guard let screen = window.screen ?? NSScreen.main else { return }
                
                let screenFrame = screen.visibleFrame
                let windowSize = window.frame.size
                
                let newOrigin = CGPoint(
                    x: screenFrame.origin.x,
                    y: screenFrame.origin.y + screenFrame.height - windowSize.height
                )
                
                window.setFrameOrigin(newOrigin)
                window.close()
            }
        }
    }
}
