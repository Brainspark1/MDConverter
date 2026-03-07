//
//  MDConverterApp.swift
//  MDConverter
//
//  Created by Nihaal Garud on 11/10/2024.
//

import SwiftUI

@main
struct MDConverterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(FileHandler.shared)
        }
        .commands {
            CommandGroup(replacing: .newItem) { } // Disable the default "New" menu if not needed
            CommandMenu("File") {
                Button("Open…") {
                    FileHandler.shared.openFile()
                }
                .keyboardShortcut("O", modifiers: [.command])
                
                Button("Save") {
                    FileHandler.shared.saveFile()
                }
                .keyboardShortcut("S", modifiers: [.command])
                
                Divider()
                
                Button("Quit Markdown Editor") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("Q")
            }
        }
    }
}
