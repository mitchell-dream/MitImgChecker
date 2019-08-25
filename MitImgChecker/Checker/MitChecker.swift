//
//  MitChecker.swift
//  MitImgChecker
//
//  Created by MENGCHEN on 2019/8/22.
//  Copyright © 2019 Mitchell. All rights reserved.
//

import Cocoa

class MitChecker: NSObject {
//    var kImgDataArr = NSMutableArray.init()
    var kImgDataMap = NSMutableDictionary.init()
    var kFileDataMap = NSMutableDictionary.init()
    var kCodePrefixDataMap = NSMutableDictionary.init()
    ///获取所有图片
    func getAllImages(atPath path:String, imgType imageTypeArr:[String], blackList blackListArr:[String], codePrefixList:[String]) -> Void {
        let fileManager = FileManager.default
        let pathString = path.replacingOccurrences(of: "file:", with: "")
        if let enumerator = fileManager.enumerator(atPath: pathString) {
            for content in enumerator {
                let path = pathString+"/\(content)"
                var directoryExists = ObjCBool.init(false)
                let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
                //文件
                if !(fileExists && directoryExists.boolValue) {
                    let fileName = (path as NSString).lastPathComponent
                    let fileNameArray = fileName.components(separatedBy: ".")
                    let suffix = fileNameArray.last! as String
                    let prefix = fileNameArray.first! as String
                    var pSuffix = prefix
                    if pSuffix.contains("@2x") {
                        pSuffix = prefix.components(separatedBy:"@2x" ).first!
                    } else  if suffix.contains("@3x") {
                        pSuffix = prefix.components(separatedBy:"@3x" ).first!
                    }
                    if pSuffix.count == 0 || !imageTypeArr.contains(suffix) {
                        continue
                    }
                    ///是否是黑名单
                    var inBlackList = ObjCBool.init(false)
                    for a in blackListArr {
                        if path.contains(a) {
                            inBlackList = true
                            break
                        }
                    }
                    if inBlackList.boolValue == true {
                        continue
                    }
                    var data = NSMutableDictionary.init()
                    if (kImgDataMap.object(forKey: pSuffix) != nil) {
                    }
                    var paths = NSMutableArray.init()
                    var hasCodePrefix = ObjCBool.init(false)
                    var codePrefix = ""
                    if (kImgDataMap.object(forKey: pSuffix) != nil) {
                        data = kImgDataMap.object(forKey: pSuffix) as! NSMutableDictionary
                        paths = data.object(forKey: "data") as! NSMutableArray
                    } else {
                        data.setObject(hasCodePrefix, forKey: "hasCodePrefix" as NSCopying)
                        data.setObject(codePrefix, forKey: "codePrefix" as NSCopying)
                    }
                    let dict = NSMutableDictionary.init()
                    dict.setObject(path, forKey: "path" as NSCopying)
                    dict.setObject(suffix, forKey: "suffix" as NSCopying)
                    dict.setObject(fileName, forKey: "name" as NSCopying)
                    for b in codePrefixList {
                        if fileName.contains(b) {
                            hasCodePrefix = true
                            codePrefix = b
                            data.setObject(hasCodePrefix, forKey: "hasCodePrefix" as NSCopying)
                            data.setObject(codePrefix, forKey: "codePrefix" as NSCopying)
                            break
                        }
                    }
                    if path.contains(".imageset") {
                        let firstStr = path.components(separatedBy: ".imageset/").first
                        let imageSetStr = firstStr?.components(separatedBy: "/").last
                        var map = NSMutableDictionary.init()
                        if (data.object(forKey: "imageset") != nil) {
                            map = data.object(forKey: "imageset") as! NSMutableDictionary
                        }
                        map.setValue(imageSetStr, forKey: imageSetStr!)
                        data.setValue(map, forKey: "imageset")
                    }
                    paths.add(dict)
                    data.setValue(paths, forKey: "data")
//                    kImgDataArr.add(dict)
                    kImgDataMap.setObject(data, forKey: pSuffix as NSCopying)
                }
            }
        }
//        print("\(kImgDataMap)")
    }
    
    func removeAll() -> Void {
        kImgDataMap.removeAllObjects()
//        kImgDataArr.removeAllObjects()
        kFileDataMap.removeAllObjects()
    }
    
    ///获取所有文件
    func getFiles(atPath path:String, fileType fileTypeArr:[String], blackList fileBlackArr:[String]) -> Void {
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(atPath: path) {
            for content in enumerator {
                let path = path+"/\(content)"
                var directoryExists = ObjCBool.init(false)
                let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
                //如果是文件
                if !(fileExists && directoryExists.boolValue) {
                    let fileName = (path as NSString).lastPathComponent
                    let fileNameArray = fileName.components(separatedBy: ".")
                    let suffix = fileNameArray.last! as String
                    let prefix = fileNameArray.first! as String
                    let pSuffix = prefix
                    if pSuffix.count == 0 || !fileTypeArr.contains(suffix) {
                        continue
                    }
                    
                    var inBlackList = ObjCBool.init(false)
                    for a in fileBlackArr {
                        if path.contains(a) {
                            inBlackList = true
                            break
                        }
                    }
                    if inBlackList.boolValue == true {
                        continue
                    }
                    var paths = NSMutableArray.init()
                    if (kFileDataMap.object(forKey: pSuffix) != nil) {
                        paths = kFileDataMap.object(forKey: pSuffix) as! NSMutableArray
                    }
                    let dict = NSMutableDictionary.init()
                    dict.setObject(path, forKey: "path" as NSCopying)
                    dict.setObject(suffix, forKey: "suffix" as NSCopying)
                    dict.setObject(fileName, forKey: "name" as NSCopying)
                    paths.add(dict)
                    kFileDataMap.setObject(paths, forKey: pSuffix as NSCopying)
                }
            }
        }
    }
    
    
    func startCheck() -> NSMutableArray {
        var copyImgData = kImgDataMap.copy() as! NSDictionary
        var copyFileData = kFileDataMap.copy() as! NSDictionary
        var keys = (copyFileData as NSDictionary).allKeys
//        print("(before=\(kImgDataMap.allKeys))")
        //遍历所有的文件内容，如果文件中
        for key in keys as NSArray {
            for item in copyFileData.value(forKey: key as! String) as! NSArray {
                let dict = item as! NSDictionary
                let path = dict.object(forKey: "path")
                if let aStreamReader = MitLineReader(path: path as! String) {
                    defer {
                        aStreamReader.close()
                    }
                    while let line:String = aStreamReader.nextLine() {
                        for image in copyImgData.allKeys {
                            let data = copyImgData.value(forKey: image as! String) as! NSMutableDictionary
                            let hasCodePrefix = data.object(forKey: "hasCodePrefix") as! ObjCBool
                            let codePrefix = data.object(forKey: "codePrefix") as! String
                            if (line.range(of: image as! String) != nil) {
                                //图片前缀检测
//                                print("removePic \(image) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
                                kImgDataMap.removeObject(forKey: image)
                            } else if (hasCodePrefix.boolValue == true) {
                                if (line.range(of: codePrefix ) != nil) {
//                                    print("removeCodePrefix \(codePrefix) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
                                    //代码中使用检测
                                    kImgDataMap.removeObject(forKey: image)
                                }
                            } else if (data.object(forKey: "imageset") != nil) {
                                //imageset 前缀修改检测
                                let map = data.object(forKey: "imageset") as! NSMutableDictionary
                                for key in map.allKeys {
                                    if (line.range(of: key as!String) != nil) {
                                        kImgDataMap.removeObject(forKey: image)
                                        break
                                    }
                                }
                            }
                        }
                        copyImgData = kImgDataMap
                    }
                }
            }
        }
        print("(afterremove=\(kImgDataMap.allKeys))")
        let result = NSMutableArray.init()
        for data in kImgDataMap.allValues as NSArray {
            let dict = data as! NSMutableDictionary
            let paths = dict.value(forKey: "data") as! NSArray
            for path in paths {
                result.add(path)
            }
        }
        return result
    }
}
