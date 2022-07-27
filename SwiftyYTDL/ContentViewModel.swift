//
//  ContentViewModel.swift
//  SwiftyYTDL
//
//  Created by Danylo Kostyshyn on 23.07.2022.
//

import Foundation
import Combine
import YTDLKit

class ContentViewModel: ObservableObject {
    
    @Published var downloads = [DownloadHandler]()
    @Published var items = [Downloadable]()
    
    private var workingQueue = DispatchQueue(label: "org.kostyshyn.YTDLKit.workingQueue")
    
    private var cancellables = [AnyCancellable]()
    
#if DEBUG
    let debugResources = [
        ("Twitter", "https://twitter.com/walter_report/status/1548520492377591809"),
        ("YouTube", "https://www.youtube.com/watch?v=Z8Z51no1TD0"),
        ("Instagram (TV)", "https://www.instagram.com/tv/CbR3FbMg3o0"),
        ("Instagram (Reel)", "https://www.instagram.com/reel/CUfNUg-IJ-R"),
        ("Instagram (Post)", "https://www.instagram.com/p/CgC-Ayyr6xF"),
        ("TikTok", "https://www.tiktok.com/t/ZTRA7ySu8/?k=1")
    ]
#endif
    
    func string(from bytes: Int64) -> String {
        Formatter.shared.byteFormatter.string(fromByteCount: bytes)
    }
    
    var footerText: String {
        "yt-dpl: \(YTDL.shared.version ?? "N\\A")"
    }
    
    func extractInfo(from url: URL, completion: @escaping (Result<Bool, Error>) -> Void) {
        workingQueue.async {
            do {
                let results = try YTDL.shared.extractInfo(from: url)
                DispatchQueue.main.async { [weak self] in
                    self?.items = results
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure("Failed to extract info from URL"))
                }
            }
        }
    }
    
    func download(_ item: Downloadable,
                  from url: URL, playlistIdx: Int = 1,
                  update: @escaping (Int64?, Int64?) -> Void,
                  completion: @escaping (Result<Bool, Error>) -> Void) {
        let handle = DownloadHandler(item)
        cancellables.append(
            handle.finishPublisher.sink { [weak self] result in
                self?.objectWillChange.send()
                
                switch result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
        cancellables.append(
            handle.updatePublisher.sink { [weak self] in
                self?.objectWillChange.send()
            }
        )
        downloads.append(handle)

        workingQueue.async {
            do {
                handle.status = .loading
                try YTDL.shared.download(
                    from: url, playlistIdx: playlistIdx,
                    updateHandler: { downloadedBytes, totalBytes in
                        handle.totalBytesWritten = downloadedBytes
                        handle.totalBytesExpectedToWrite = totalBytes
                        handle.progress = Double(downloadedBytes) / Double(totalBytes)
                        handle.updateSubject.send()
                    },
                    completionHandler: { result in
                        switch result {
                        case .success(let fileURL):
                            handle.status = .finished
                            do {
                                try PhotosManager.saveToPhotos(at: fileURL)
                                handle.finishSubject.send(.success(true))
                            } catch {
                                handle.finishSubject.send(.failure(error))
                            }
                        case .failure(let error):
                            handle.status = .error
                            handle.finishSubject.send(.failure(error))
                        }
                    }
                )
            } catch {
                handle.status = .error
                handle.finishSubject.send(.failure(error))
            }
        }
    }
    
}

class DownloadHandler: ObservableObject {
    
    let id = UUID()
    var item: Downloadable
    
    let updateSubject = PassthroughSubject<Void, Never>()
    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject
            .receive(on: DispatchQueue.main)
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }

    let finishSubject = PassthroughSubject<Result<Bool, Error>, Never>()
    var finishPublisher: AnyPublisher<Result<Bool, Error>, Never> {
        finishSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
        
    @Published var progress: Double = 0.0
    @Published var totalBytesWritten: Int64 = 0
    @Published var totalBytesExpectedToWrite: Int64 = 0
    
    enum Status { case initial, loading, finished, error }
    @Published var status: Status = .initial
    
    init(_ item: Downloadable) {
        self.item = item
    }
    
}
