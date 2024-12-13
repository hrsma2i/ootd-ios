//
//  SnackbarStore.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/02.
//

import Foundation

class SnackbarStore: ObservableObject {
    @Published var active: Snackbar?

    @MainActor
    private func dismiss() {
        active = nil
    }

    @MainActor
    func notify(_ logger: CustomLogger, process: @escaping () async throws -> Void) async {
        do {
            try await process()
            notifySuccess()
        } catch {
            logger.critical("\(error)")
            notifyFailure()
        }
    }

    @MainActor
    private func notifySuccess() {
        active = Snackbar(
            message: "成功しました",
            buttonText: "閉じる"
        ) {
            self.dismiss()
        }
    }

    @MainActor
    private func notifyFailure() {
        active = Snackbar(
            message: "失敗しました",
            buttonText: "閉じる",
            buttonTextColor: .white,
            backgroundColor: .softRed
        ) {
            self.dismiss()
        }
    }
}
