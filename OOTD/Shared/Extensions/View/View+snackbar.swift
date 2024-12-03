//
//  View+snackbar.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/02.
//

import SwiftUI

struct SnackbarModifier<SnackbarContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    @ViewBuilder let snackbarContent: () -> SnackbarContent

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isPresented {
                    snackbarContent()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity)) // スライドイン + フェード
                        .task {
                            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                            withAnimation {
                                isPresented = false
                            }
                        }
                } else {
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: isPresented)
    }
}

struct SnackbarItemModifier<Item: Hashable, SnackbarContent: View>: ViewModifier {
    @Binding var item: Item?
    let duration: TimeInterval
    @ViewBuilder let snackbarContent: (Item) -> SnackbarContent

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let item = item {
                    snackbarContent(item)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity)) // スライドイン + フェード
                        .task {
                            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                            withAnimation {
                                self.item = nil
                            }
                        }
                } else {
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: item)
    }
}

extension View {
    func snackbar<SnackbarContent: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 3.0,
        @ViewBuilder snackbarContent: @escaping () -> SnackbarContent
    ) -> some View {
        modifier(SnackbarModifier(isPresented: isPresented, duration: duration, snackbarContent: snackbarContent))
    }

    func snackbar<Item: Hashable, SnackbarContent: View>(
        item: Binding<Item?>,
        duration: TimeInterval = 3.0,
        @ViewBuilder snackbarContent: @escaping (Item) -> SnackbarContent
    ) -> some View {
        modifier(SnackbarItemModifier(item: item, duration: duration, snackbarContent: snackbarContent))
    }
}

#Preview {
    struct PreviewView: View {
        @State var activeSnackbar: Snackbar?

        var body: some View {
            VStack(spacing: 50) {
                Button("show success snackbar") {
                    activeSnackbar = Snackbar(
                        message: "保存されました",
                        buttonText: "閉じる"
                    ) {
                        activeSnackbar = nil
                    }
                }

                Button("show failure snackbar") {
                    activeSnackbar = Snackbar(
                        message: "失敗しました",
                        buttonText: "閉じる",
                        buttonTextColor: .white,
                        backgroundColor: .red
                    ) {
                        activeSnackbar = nil
                    }
                }
                .foregroundColor(.red)
            }
            .snackbar(item: $activeSnackbar) { $0 }
        }
    }

    return PreviewView()
}
