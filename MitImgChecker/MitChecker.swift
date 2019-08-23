//
//  MitChecker.swift
//  MitImgChecker
//
//  Created by MENGCHEN on 2019/8/22.
//  Copyright © 2019 Mitchell. All rights reserved.
//

import Cocoa

class MitChecker: NSObject {
/*
     1、根据图片类型获取所有图片
     2、遍历所有文件，查看文件是否有使用
     3、如果有使用，5000f * 1000 次
     */
    var kImgDataArr = NSMutableArray.init()
    var kImgDataMap = NSMutableDictionary.init()
    var kFileDataMap = NSMutableDictionary.init()
    ///获取所有图片
    func getAllImages(atPath path:String, imgType imageTypeArr:[String], blackList blackListArr:[String]) -> Void {
        let fileManager = FileManager.default
        let pathString = path.replacingOccurrences(of: "file:", with: "")
        if let enumerator = fileManager.enumerator(atPath: pathString) {
            for content in enumerator {
                let path = pathString+"/\(content)"
                var directoryExists = ObjCBool.init(false)
                let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
                //文件
                if !(fileExists && directoryExists.boolValue) {
//                    getAllImages(atPath: path, imgType: imageTypeArr, blackList: blackListArr)
//                } else {
                    //文件
                    let fileName = (path as NSString).lastPathComponent
                    let fileNameArray = fileName.components(separatedBy: ".")
                    let suffix = fileNameArray.last! as String
                    let prefix = fileNameArray.first! as String
                    var pSuffix = prefix
                    if pSuffix.contains("@2x") {
                        pSuffix = prefix.components(separatedBy:"@2x" ).first as! String
                    } else  if suffix.contains("@3x") {
                        pSuffix = prefix.components(separatedBy:"@3x" ).first as! String
                    }
                    if pSuffix.count == 0 || !imageTypeArr.contains(suffix) {
                        continue
                    }
                    var inBlackList = ObjCBool.init(false)
                    for a in blackListArr {
                        if path.contains(a) {
                            inBlackList = true
                            break
                        }
                    }
                    if inBlackList.boolValue == true {
                        return
                    }
                    
                    if (kImgDataMap.object(forKey: pSuffix) != nil) {
                        let paths = kImgDataMap.object(forKey: pSuffix) as! NSMutableArray
                        let ldict = NSMutableDictionary.init()
                        ldict.setObject(path, forKey: "path" as NSCopying)
                        ldict.setObject(suffix, forKey: "suffix" as NSCopying)
                        ldict.setObject(fileName, forKey: "name" as NSCopying)
                        paths.add(ldict)
                        kImgDataMap.setObject(paths, forKey: pSuffix as NSCopying)
                        kImgDataArr.add(ldict)
                    } else {
                        let paths = NSMutableArray.init()
                        let dict = NSMutableDictionary.init()
                        dict.setObject(path, forKey: "path" as NSCopying)
                        dict.setObject(suffix, forKey: "suffix" as NSCopying)
                        dict.setObject(fileName, forKey: "name" as NSCopying)
                        paths.add(dict)
                        kImgDataArr.add(dict)
                        kImgDataMap.setObject(paths, forKey: pSuffix as NSCopying)
                    }
                }
            }
        }
        print("\(kImgDataMap)")
    }
    
    ///获取所有文件
    func getFiles(atPath path:String, fileType fileTypeArr:[String]) -> Void {
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(atPath: path) {
            for content in enumerator {
                let path = path+"/\(content)"
                print("content=\(content)")
                var directoryExists = ObjCBool.init(false)
                let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
                //如果是文件
                if !(fileExists && directoryExists.boolValue) {
//                    print("directory path=\(path)")
////                    getFiles(atPath: path, fileType: fileTypeArr)
//                } else {
                    print("fileHandle \(path)")
                    let fileName = (path as NSString).lastPathComponent
                    let fileNameArray = fileName.components(separatedBy: ".")
                    let suffix = fileNameArray.last! as String
                    let prefix = fileNameArray.first! as String
                    let pSuffix = prefix
                    if pSuffix.count == 0 || !fileTypeArr.contains(suffix) {
                        continue
                    }
                    if (kFileDataMap.object(forKey: pSuffix) != nil) {
                        let paths = kFileDataMap.object(forKey: pSuffix) as! NSMutableArray
                        let ldict = NSMutableDictionary.init()
                        ldict.setObject(path, forKey: "path" as NSCopying)
                        ldict.setObject(suffix, forKey: "suffix" as NSCopying)
                        ldict.setObject(fileName, forKey: "name" as NSCopying)
                        paths.add(ldict)
                        kFileDataMap.setObject(paths, forKey: pSuffix as NSCopying)
                    } else {
                        let paths = NSMutableArray.init()
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
    }
    
    
    func startCheck() -> NSMutableArray {
        var copyImgData = kImgDataMap.copy() as! NSDictionary
        var copyFileData = kFileDataMap.copy() as! NSDictionary
        var keys = (copyFileData as NSDictionary).allKeys
        print("(before=\(kImgDataMap.allKeys))")
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
                            if (line.range(of: image as! String) != nil) {
                                print("removePic \(image) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
                                kImgDataArr.remove(copyImgData.value(forKey: image as! String))
                                kImgDataMap.removeObject(forKey: image)
                                break
                            }
                        }
                        copyImgData = kImgDataMap
                    }
                }
            }
        }
        print("(afterremove=\(kImgDataMap.allKeys))")
        return kImgDataArr
    }
}
