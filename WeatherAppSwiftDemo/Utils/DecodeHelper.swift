
//
//  DecodeHelper.swift
//  demopackage
//
//  Created by work on 2024/12/17.
//

import Foundation

class DecodeHelper {
    
    /// 将 [String: Any]? 转换为 JSON 字符串
    /// - Parameter dictionary: 输入的字典
    /// - Returns: 格式化的 JSON 字符串
    static func dictionaryToJSONString(_ dictionary: [String: Any]?) -> String? {
        guard let dictionary = dictionary else {
            print("❌ 输入字典为空")
            return nil
        }
        
        do {
            // 1. 使用 JSONSerialization 将字典转换为 Data
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
            
            // 2. 将 Data 转换为 String
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("❌ 字典转换为 JSON 字符串失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    /// 将 Data 转换为 [String: Any] 字典
    /// - Parameter data: 输入的 Data
    /// - Returns: 转换后的字典 [String: Any]，转换失败时返回 nil
    static func toDictionary(from data: Data) -> [String: Any]? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = jsonObject as? [String: Any] {
                return dictionary
            }
        } catch {
            print("❌ JSON 转换为字典失败: \(error.localizedDescription)")
        }
        return nil
    }
    static func toPrettyJSONString(from input: Any) -> String? {
        do {
            var data: Data
            
            // 判断输入的类型
            if let dictionary = input as? [String: Any] {
                // 如果是字典，将其转为 Data
                data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            } else if let dataInput = input as? Data {
                // 如果是 Data 类型，直接使用
                data = dataInput
            } else {
                // 如果输入不是 [String: Any] 或 Data，返回 nil
                print("❌ Invalid input type")
                return nil
            }
            
            // 将 Data 转为 JSON 对象
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            // 将 JSON 对象转为漂亮格式的 Data
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject)
            
            // 将 Data 转为字符串并返回
            if let jsonString = String(data: prettyData, encoding: .utf8) {
                return jsonString
            }
            
        } catch {
            print("❌ JSON 转换为 Pretty 字符串失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    static func convertJSONStringToDictionary(_ jsonString: String) -> [String: Any]? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ 无法将字符串转换为 Data")
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let dictionary = jsonObject as? [String: Any] {
                return dictionary
            } else {
                print("❌ 转换结果不是字典类型")
                return nil
            }
        } catch {
            print("❌ JSON 解析失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 将 [String: Any] 转换为 Codable 对象
    static func decode<T: Codable>(_ type: T.Type, _ dictionary: Any) throws -> T? {
           do {
               // 将字典转换为 Data
               
               let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
               let decodedObject = try JSONDecoder().decode(T.self, from: data)
               return decodedObject
           } catch {
               // 捕获并抛出异常
               print("Decoding error: \(error)")
               throw error // 抛出解码错误
           }
       }
      
      static func encode<T: Codable>(_ object: T) -> [String: Any]? {
          do {
              let data = try JSONEncoder().encode(object)
              let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
              return jsonObject as? [String: Any]
          } catch {
              print("Encoding error: \(error)")
              return nil
          }
      }
}
