//
//  Untitled.swift
//  WeatherAppSwiftDemo
//
//  Created by work on 2025/2/26.
//

import Foundation
import CryptoKit

protocol NetworkServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (Result<WeatherData, Error>) -> Void)
}

final class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        let requestDate = Date()
        
        let urlString = "\(baseURL)?latitude=\(latitude)&longitude=\(longitude)&hourly=temperature_2m"
        guard let url = URL(string: urlString) else {
            logNetworkEvent(.invalidURL(urlString))
            completion(.failure(NetworkError.invalidURL))
            return
        }
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60

        let session = URLSession(configuration: configuration)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        logNetworkEvent(.requestSent(request))
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let `self` = self else {return }
            let responseDate = Date()
            let latency = responseDate.timeIntervalSince(requestDate)
            if let error = error {
                self.logNetworkEvent(.transportError(error),
                                     latency: latency)
                completion(.failure(error))
                return
            }
            // HTTP响应验证
            guard let _ = response as? HTTPURLResponse else {
                         self.logNetworkEvent(.invalidResponse,
                                              latency: latency)
                         completion(.failure(NetworkError.invalidResponse))
                         return
            }
                     
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let weatherData = try decoder.decode(WeatherData.self, from: data)
                self.logNetworkEvent(.decodeSuccess(data),
                                     latency: latency)
                completion(.success(weatherData))
            } catch {
                completion(.failure(NetworkError.decodeFailed))
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case invalidURL, noData, decodeFailed,invalidResponse
}



// MARK: - 安全日志基础设施
private extension NetworkService {
    enum NetworkEvent {
        case invalidURL(String)
        case requestSent(URLRequest)
        case transportError(Error)
        case invalidResponse
        case responseReceived(HTTPURLResponse)
        case emptyData(Int)
        case dataFingerprint(hash: String, bytes: Int)
        case decodeSuccess(_ data:Any)
        case decodeFailed(Error)
    }
    
    func logNetworkEvent(_ event: NetworkEvent,
                         latency: TimeInterval? = nil) {
#if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(),
                                                      dateStyle: .medium,
                                                      timeStyle: .medium)
        var message = "[\(timestamp)]"
        
        switch event {
        case .invalidURL(let url):
            message += " ❌ 无效URL: \(url.sanitizedQueryParams)"
        case .requestSent(let request):
            let headers = request.allHTTPHeaderFields?.map { $0 }
            message += """
            ⏫ 请求发送
            URL: \(request.url?.absoluteString.sanitizedQueryParams ?? "nil")
            Method: \(request.httpMethod ?? "GET")
            Headers: \(String(describing: headers))
            """
        case .transportError(let error):
            message += " 🚧 传输层错误: \(error.localizedDescription)"
        case .invalidResponse:
            message += " ❓ 无效响应: 非HTTP协议响应"
        case .responseReceived(let response):
            message += """
            ⏬ 收到响应
            Status: \(response.statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))
            Headers: \(response.allHeaderFields.description)
            """
        case .emptyData(let statusCode):
            message += " 📭 空数据包: HTTP \(statusCode)"
        case .dataFingerprint(let hash, let bytes):
            message += " 🔍 数据指纹: SHA256=\(hash.prefix(8)), Size=\(bytes.formattedByteSize)"
        case .decodeSuccess(let response):
            message += " ✅ 解码成功 \n".appending(DecodeHelper.toPrettyJSONString(from: response) ?? "")
        case .decodeFailed(let error):
            message += " 💥 解码失败: \(error.localizedDescription)"
        }
        
        if let latency = latency {
            message += "\n⏱ 请求耗时: \(String(format: "%.2f", latency))秒"
        }
        
        Logger.debug("""
        ----------------------------------------------------------
        \(message)
        ----------------------------------------------------------
        """)
#endif
    }
}

// MARK: - 数据安全扩展（防止日志泄露敏感信息）
private extension String {
    var sanitizedQueryParams: String {
        guard var components = URLComponents(string: self) else { return self }
        components.sanitizeQueryParams()
        return components.url?.absoluteString ?? self
    }
}

private extension Dictionary where Key == String, Value == Any {
    var sanitized: [Key: Value] {
        // 过滤敏感header （例如Authorization）
        return self.filter { key, _ in
            !key.lowercased().contains("auth")
        }
    }
}

private extension URLComponents {
    mutating func sanitizeQueryParams() {
        // 过滤敏感参数（示例）
        let sensitiveParams = ["password", "token"]
        queryItems = queryItems?.filter { !sensitiveParams.contains($0.name) }
    }
}


extension Int {
    var formattedByteSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }
}
