//
//  APIService.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = APIConfig.baseURL
    private let session = URLSession.shared
    private let keychainService = KeychainService.shared
    
    private init() {}
    
    // MARK: - Generic Request Method
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if required and token exists
        if requiresAuth, let token = keychainService.getJWTToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                // Token expired or invalid
                keychainService.clearAll()
                throw APIError.unauthorized
            case 400...499:
                // Try to parse error message from response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorData["message"] as? String {
                    throw APIError.serverError(message)
                }
                throw APIError.serverError("Client error")
            case 500...599:
                throw APIError.serverError("Server error")
            default:
                throw APIError.invalidResponse
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Request with no response body
    
    func requestWithoutResponse(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = keychainService.getJWTToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return
            case 401:
                keychainService.clearAll()
                throw APIError.unauthorized
            default:
                throw APIError.serverError("Request failed")
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Convenience methods for encoding request bodies
    
    func encode<T: Codable>(_ object: T) throws -> Data {
        return try JSONEncoder().encode(object)
    }
}
