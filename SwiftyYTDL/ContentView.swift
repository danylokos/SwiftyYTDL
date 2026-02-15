//
//  ContentView.swift
//  SwiftyYTDL
//
//  Created by Danylo Kostyshyn on 20.07.2022.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel: ContentViewModel
    
    @State var isLoading: Bool = false
    @State var isActionSheetVisible: Bool = false
    
    @State var error: Error?
    @State var pastedLink: String?

    var body: some View {
        ZStack {
            VStack {
            List {
                pasteboardSection()
                downloadsSection()
            #if DEBUG
                debugResourcesSection()
            #endif
            }.listStyle(InsetGroupedListStyle())
                Text(viewModel.footerText)
                    .foregroundColor(.secondary)
                    .font(.callout)
            }.background(Color(uiColor: .systemGroupedBackground))
            if isLoading {
                LoadingView()
                    .offset(y: -50.0)
            }
        }
        .navigationTitle("SwiftyYTDL")
        .confirmationDialog(
            "Download",
            isPresented: $isActionSheetVisible,
            titleVisibility: .visible
        ) {
            ForEach(viewModel.items.enumerated().map({ $0 }), id: \.element.id) { idx, item in
                Button(item.description) {
                    isActionSheetVisible = false
                    isLoading = true
                    viewModel.download(
                        item, from: item.browserUrl,
                        playlistIdx: idx + 1,
                        update: { _, _ in }
                    ) { result in
                        defer { isLoading = false }
                        switch result {
                        case .success:
                            break
                        case .failure(let err):
                            error = err
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                isActionSheetVisible = false
            }
        }
        .errorAlert(error: $error)
    }
    
    func pasteboardSection() -> some View {
        Section {
            Button(action: {
                pastedLink = UIPasteboard.general.string
            }) {
                Text("Paste URL")
            }
        }.alert("Download", isPresented: .constant($pastedLink.wrappedValue != nil)) {
            Button(action: {
                $pastedLink.wrappedValue = nil
            }) {
                Text("Cancel")                
            }
            Button(action: {
                defer {
                    $pastedLink.wrappedValue = nil
                }
                
                guard
                    let url = pastedLink.flatMap({ URL(string: $0) })
                else {
                    error = "Invalid URL"
                    return
                }
                
                isLoading = true
                viewModel.extractInfo(from: url) { result in
                    defer {
                        isLoading = false
                    }
                    switch result {
                    case .success(let value):
                        isActionSheetVisible = value
                    case .failure(let err):
                        isActionSheetVisible = false
                        error = err
                    }
                }
            }) {
                Text("Download")
            }
        } message: {
            Text($pastedLink.wrappedValue ?? "")
        }
    }
    
    func downloadsSection() -> some View {
        Section {
            ForEach(viewModel.downloads, id: \.id) { item in
                VStack(alignment: .leading, spacing: 10.0) {
                    Text(item.item.title)
                    switch item.status {
                    case .initial:
                        Divider()
                        Text(viewModel.string(from: item.totalBytesExpectedToWrite))
                    case .loading:
                        ProgressView(value: item.progress)
                        Text("⬇️ " + (viewModel.string(from: item.totalBytesWritten)) + " of " +
                             (viewModel.string(from: item.totalBytesExpectedToWrite)))
                    case .finished:
                        Divider()
                        Text("✅ " + viewModel.string(from: item.totalBytesExpectedToWrite))
                    case .error:
                        Divider()
                        Text("🛑 " + viewModel.string(from: item.totalBytesExpectedToWrite))
                    }
                }.padding([.top, .bottom], 5.0)
            }
        }
    }
    
#if DEBUG
    func debugResourcesSection() -> some View {
        Section("Debug") {
            ForEach(viewModel.debugResources, id: \.0) { title, link in
                Button(action: {
                    pastedLink = link
                }) {
                    Text(title)
                }
            }
        }
    }
#endif
    
}

extension View {
    
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        return alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button(action: {
                error.wrappedValue = nil
            }) {
                Text("OK")
            }
        } message: {
            Text(error.wrappedValue?.localizedDescription ?? "Unknown error")
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewModel())
    }
}

