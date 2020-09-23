//
//  MitChecker.swift
//  MITSourceChecker
//
//  Created by MENGCHEN on 2019/8/22.
//  Copyright © 2019 Mitchell. All rights reserved.
//

import Cocoa
import CommonCrypto
import CoreFoundation
import AppKit

class MitChecker: NSObject {
    var kImgDataMap = NSMutableDictionary.init()
    var kFileDataMap = NSMutableDictionary.init()
    var kCategoryHFileDataMap = NSMutableDictionary.init()
    var kCategoryRepeatHFileDataMap = NSMutableDictionary.init()
    var kCodePrefixDataMap = NSMutableDictionary.init()
    var souceTypes=NSArray.init()
    var patternMap=NSMutableDictionary.init()
    var md5Map = NSMutableDictionary.init()
    var copyImgData = NSDictionary.init()//kImgDataMap.copy() as! NSDictionary
    var copyFileData = NSDictionary.init()//kFileDataMap.copy() as! NSDictionary
    let keylock = NSObject.init()
    let imgLock = NSObject.init()
    let imageSetMap = NSMutableDictionary.init()
    let codePrefixMap = NSMutableDictionary.init()
    var isStop = false
    public var currentProgressStr: ((String)->())?

    ///获取所有图片
    func getAllImages(atPath path:String, imgType imageTypeArr:[String], blackList blackListArr:[String], codePrefixList:[String]) -> Void {
        self.initialPattern()
        let fileManager = FileManager.default
        let pathString = path.replacingOccurrences(of: "file:", with: "")
        self.souceTypes = imageTypeArr as NSArray
        if let enumerator = fileManager.enumerator(atPath: pathString) {
            autoreleasepool {
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
                                self.codePrefixMap[codePrefix]=pSuffix
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
                            self.imageSetMap[imageSetStr] = pSuffix
                        }
                        let md5result = self.md5File(filePath: path)
                        var md5arr = md5Map.object(forKey: md5result) as? NSMutableArray
                        if (md5arr != nil) {
                            md5arr?.add(path)
                        } else {
                            md5arr = NSMutableArray.init()
                            md5arr!.add(path)
                        }
                        md5Map.setObject(md5arr as Any, forKey: md5result as NSCopying)
                        paths.add(dict)
                        data.setValue(paths, forKey: "data")
                        kImgDataMap.setObject(data, forKey: pSuffix as NSCopying)
                    }
                }
            }
        }
//        print("所有图片 = \(kImgDataMap)")
    }
    
    func removeAll() -> Void {
        kImgDataMap.removeAllObjects()
        kFileDataMap.removeAllObjects()
    }
    func stop() -> Void {
        self.isStop = true
    }
    
    func initialPattern(){
        let hPattern = String(format:"([a-zA-Z0-9_-]*)\\.(%@)", arguments:[self.souceTypes.componentsJoined(by: "|")])
        let mPattern = "@\"(.*?)\"";
        let xibPattern = "image name=\"(.+?)\""
        let htmlPattern="img\\s+src=[\"\'](.*?)[\"\']"
        let jsPattern = "[\"\']src[\"\'],\\s+[\"\'](.*?)[\"\']"
        let jsonPattern = ":\\s*\"(.*?)\""
        let plistPattern = ">(.*?)<"
        let swiftPattern = "\"(.*?)\""
        let stringPattern = "=\\s*\"(.*)\"\\s*;"
        self.patternMap["h"]=hPattern
        self.patternMap["cpp"]=hPattern
        self.patternMap["c"] = hPattern
        self.patternMap["m"]=mPattern
        self.patternMap["mm"]=mPattern
        self.patternMap["html"]=htmlPattern
        self.patternMap["xib"]=xibPattern
        self.patternMap["storyboard"]=xibPattern
        self.patternMap["swift"]=swiftPattern
        self.patternMap["plist"]=plistPattern
        self.patternMap["json"]=jsonPattern
        self.patternMap["js"]=jsPattern
        self.patternMap["strings"]=stringPattern
        self.patternMap["others"]=mPattern
    }
    
    
    ///获取所有文件
    func getSourceFiles(atPath path:String, fileType fileTypeArr:[String], blackList fileBlackArr:[String]) -> Void {
        let fileManager = FileManager.default
        print("totalpath=\(path)")

        if let enumerator = fileManager.enumerator(atPath: path) {
            autoreleasepool {
            for content in enumerator {
                if (self.isStop == true) {
                    break;
                }
//                print("获取文件 = \(content)")
                let path = path+"/\(content)"
//                print("path=\(path)")
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
//        print("所有文件 = \(kFileDataMap)")
    }
    
    ///获取所有文件
    func getCategoryHFiles(atPath path:String, fileType fileTypeArr:[String], blackList fileBlackArr:[String]) -> Void {
        let fileManager = FileManager.default
        print("totalpath=\(path)")
        if let enumerator = fileManager.enumerator(atPath: path) {
            autoreleasepool {
            for content in enumerator {
                let path = path+"/\(content)"
//                print("path=\(path)")
                var directoryExists = ObjCBool.init(false)
                let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
                //如果是文件
                if !(fileExists && directoryExists.boolValue) {
                    let fileName = (path as NSString).lastPathComponent
                    if !fileName.contains("+") {
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
                    let fileNameArray = fileName.components(separatedBy: ".")
                    // 文件名称后缀
                    let suffix = fileNameArray.last! as String
                    // 文件名称前缀
                    let prefix = fileNameArray.first! as String
                    let pSuffix = prefix
                    if pSuffix.count == 0 || !fileTypeArr.contains(suffix) {
                        continue
                    }
                    var paths = NSMutableArray.init()
                    // 获取同一个 key 下的文件数组
                    if (kCategoryHFileDataMap.object(forKey: pSuffix) != nil) {
                        // 获取数组下的路径
                        paths = kCategoryHFileDataMap.object(forKey: pSuffix) as! NSMutableArray
                    }
                    let dict = NSMutableDictionary.init()
                    dict.setObject(path, forKey: "path" as NSCopying)
                    dict.setObject(suffix, forKey: "suffix" as NSCopying)
                    dict.setObject(fileName, forKey: "name" as NSCopying)
                    
                    //查看是否有重复
                    for fp in paths
                    {
                        var result = fp as! NSMutableDictionary
                        if (result.object(forKey: "name") as! String ==  fileName)
                        {
                            var repeatPaths = NSMutableArray.init()
                            if (kCategoryRepeatHFileDataMap.object(forKey: fileName) != nil) {
                                repeatPaths = kCategoryRepeatHFileDataMap.object(forKey: fileName) as! NSMutableArray;
                            }
                            if (!repeatPaths.contains(dict)) {
                                repeatPaths.add(dict)
                            }
                            if (!repeatPaths.contains(result)) {
                                repeatPaths.add(result)
                            }
                            kCategoryRepeatHFileDataMap.setObject(repeatPaths, forKey: fileName as NSCopying)
                        }
                    }
                    
                    paths.add(dict)
                    kCategoryHFileDataMap.setObject(paths, forKey: pSuffix as NSCopying)
                }
            }
            }
        }
//        print("所有文件 = \(kCategoryHFileDataMap)")
//        print("重复文件 = \(kCategoryRepeatHFileDataMap)")
//        startParseCategoryFiles()
    }
    
    // 解析分类头文件内容，
//    func startParseCategoryFiles(){
//        for key in kCategoryHFileDataMap.allKeys {
//            print("key = \(key)")
//            var pathDicts = kCategoryHFileDataMap.object(forKey: key) as! NSMutableArray
//            for obj in pathDicts {
//                var fp = (obj as AnyObject).object(forKey: "path") as! String
//                fp = "file://"+fp
//                print("fp = \(fp)")
//                let newUrl = fp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//                let url = URL.init(string: newUrl) as! URL
//                let codeData = try? Data.init(contentsOf: url)
//                // 文件内容
//                let codeString = String(data: codeData!, encoding: String.Encoding.utf8)
//                print(codeString!)
//                let lexer = MitHLexer.init(inputCodeString: codeString!)
//                lexer.analysis()
//            }
//        }
//    }
    
    
    
    func Lock(object:AnyObject, callBack:()->()){
        objc_sync_enter(object)
        callBack()
        objc_sync_exit(object)
    }
    
    func matchContent(content:String, pattern:String)-> NSSet {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.matches(in: content, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, content.count))
            let set = NSMutableSet.init()
            if res.count > 0 {
                for checkingRes in res
                {
                    //从 1 开始排除 @
                    var result = (content as NSString).substring(with: checkingRes.range(at: 1)) as NSString?
                    if (result!.length > 0) {
                        result = result?.lastPathComponent as NSString?
//                        print("aaa+=\(result)")
                        set.add(result as Any)
                    }
                }
            }
            return set
        } catch {
            print(error)
        }
        return NSSet.init()
    }
//   func getMatchStringWithContent:(NSString *)content pattern:(NSString*)pattern groupIndex:(NSInteger)index {
//        NSRegularExpression *regexExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
//        NSArray* matchs = [regexExpression matchesInString:content options:0 range:NSMakeRange(0, content.length)];
//
//        if (matchs.count) {
//            NSMutableSet *set = [NSMutableSet set];
//            for (NSTextCheckingResult *checkingResult in matchs) {
//                NSString *res = [content substringWithRange:[checkingResult rangeAtIndex:index]];
//                if (res.length) {
//                    res = [res lastPathComponent];
//                    res = [StringUtils stringByRemoveResourceSuffix:res];
//                    [set addObject:res];
//                }
//            }
//            return set;
//        }
//
//        return nil;
//    }
    
    
    func getPattern(suffix:String)->String {
        if ((self.patternMap.object(forKey: suffix)) != nil) {
            return self.patternMap.object(forKey: suffix) as! String
        } else {
            return self.patternMap.object(forKey: "others") as! String
        }
    }
    
    func startCheck(callBack:@escaping (NSMutableArray) -> Void) -> NSMutableArray {
        self.isStop = false
        let stopresult = NSMutableArray.init()
        self.copyImgData = kImgDataMap.copy() as! NSDictionary
        self.copyFileData = kFileDataMap.copy() as! NSDictionary
        var keys = (copyFileData as NSDictionary).allKeys
        //遍历所有的文件内容，如果文件中
        var current = 0.0 as Float?
        print("imageset arr = \(self.imageSetMap.allKeys)")

        for key in keys as NSArray {
            if (self.isStop == true) {
                return stopresult
            }
            let cur = current! * 100.0
            var progressString = String(format:"%.4f",(cur/Float(keys.count)))
            print("当前进度：\(progressString)%")
            if self.currentProgressStr != nil{
                self.currentProgressStr!(progressString)
            }
            current!+=1
            autoreleasepool {
                for item in copyFileData.value(forKey: key as! String) as! NSArray {
                    if (self.isStop == true) {
                        break;
                    }
                    let dict = item as! NSDictionary
                    let path = dict.object(forKey: "path")
                    let readHandler =  FileHandle(forReadingAtPath: path as! String)
                    
                    //正则匹配法
                    let data = readHandler?.readDataToEndOfFile()
                    let content:String = String(data: data!, encoding: String.Encoding.utf8)!
                    let suffix = dict.object(forKey: "suffix")
                    let pattern = self.getPattern(suffix: suffix as! String)
                    let set = matchContent(content: content, pattern: pattern)
                    if (set.count > 0){
                        print(set)
                        for img in set
                        {
                            var arr = self.copyImgData.allKeys as NSArray
                            if (arr.contains(img)==true) {
                                print("image = \(img)")

                                kImgDataMap.removeObject(forKey: img)
                            }
                            arr = self.imageSetMap.allKeys as NSArray
                            if (arr.contains(img)==true) {
                                let img = self.imageSetMap[img]
                                print("imageset = \(img)")
                                kImgDataMap.removeObject(forKey: img!)
                            }
                            arr = self.codePrefixMap.allKeys as NSArray
                            if (arr.contains(img)==true) {
                                let img = self.codePrefixMap[img]
                                print("codeprefix = \(img)")
                                kImgDataMap.removeObject(forKey: img!)
                            }
                        }
                    }
                    
                    
//                    for image in copyImgData.allKeys {
//                        if (self.isStop == true) {
//                            break;
//                        }
//                        let data = copyImgData.value(forKey: image as! String) as! NSMutableDictionary
//                        let hasCodePrefix = data.object(forKey: "hasCodePrefix") as! ObjCBool
//                        let codePrefix = data.object(forKey: "codePrefix") as! String
//                        //"imageName" || "imageName. || /imageName
//                        if ((content.contains("\"\(image)\"" ))||(content.contains("\"\(image)." ))||(content.contains("/\"\(image)"))) {
//                            kImgDataMap.removeObject(forKey: image)
//                            print("removePic \(image) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
//                        }
//                        else if (hasCodePrefix.boolValue == true) {
//                            if ((content.contains("\"\(codePrefix)\"" ))||(content.contains("\"\(codePrefix)." ))||(content.contains("/\"\(codePrefix)" ))) {
//                                print("removeCodePrefix \(codePrefix) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
//                                //代码中使用检测
//                                kImgDataMap.removeObject(forKey: image)
//                            }
//                        } else if (data.object(forKey: "imageset") != nil) {
//                            //imageset 前缀修改检测
//                            let map = data.object(forKey: "imageset") as? NSMutableDictionary
//                            for key in map!.allKeys {
//                                if ((content.contains("\"\(key)\"" ))||(content.contains("\"\(key)." ))||(content.contains("/\"\(key)" ))) {
//                                    kImgDataMap.removeObject(forKey: image)
//                                    print("removeImageset \(codePrefix) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
//                                    break
//                                }
//                            }
//                        }
//                    }
//                    copyImgData = kImgDataMap
                    
                    
                    
                    
                    
//                    if let aStreamReader = MitLineReader(path: path as! String) {
//                        defer {
//                            aStreamReader.close()
//                        }
//                        while let line:String = aStreamReader.nextLine() {
//                            if self.isStop == true {
//                                break;
//                            }
//                            for image in copyImgData.allKeys {
//                                if (self.isStop == true) {
//                                    break;
//                                }
//                                let data = copyImgData.value(forKey: image as! String) as! NSMutableDictionary
//                                let hasCodePrefix = data.object(forKey: "hasCodePrefix") as! ObjCBool
//                                let codePrefix = data.object(forKey: "codePrefix") as! String
//
//                                //"imageName" || "imageName. || /imageName
//                                if ((line.contains("\"\(image)\"" ))||(line.contains("\"\(image)." ))||(line.contains("/\"\(image)"))) {
//                                    kImgDataMap.removeObject(forKey: image)
//                                    print("removePic \(image) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
//                                }
//                                else if (hasCodePrefix.boolValue == true) {
//                                    if ((line.contains("\"\(codePrefix)\"" ))||(line.contains("\"\(codePrefix)." ))||(line.contains("/\"\(codePrefix)" ))) {
////                                    if (line.range(of: codePrefix ) != nil) {
//                                        print("removeCodePrefix \(codePrefix) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
//                                        //代码中使用检测
//                                        kImgDataMap.removeObject(forKey: image)
//                                    }
//                                } else if (data.object(forKey: "imageset") != nil) {
//                                    //imageset 前缀修改检测
//                                    let map = data.object(forKey: "imageset") as? NSMutableDictionary
//                                    for key in map!.allKeys {
//                                        if ((line.contains("\"\(key)\"" ))||(line.contains("\"\(key)." ))||(line.contains("/\"\(key)" ))) {
////                                        if (line.range(of: key as!String) != nil) {
//                                            kImgDataMap.removeObject(forKey: image)
//                                            print("removeImageset \(codePrefix) paths = \(String(describing: copyImgData.value(forKey: image as! String))))")
//                                            break
//                                        }
//                                    }
//                                }
//                            }
//                            copyImgData = kImgDataMap
//                        }
//                    }
                }
            }
        }
//        print("删除后所有图片 = \(kImgDataMap)")
        
        
        
        let result = NSMutableArray.init()
        if (self.isStop == true) {
            return result
        }
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let jsonPath = (docDir as NSString).appendingPathComponent("MitUnusedData.xlsx")
        let book = workbook_new(jsonPath)
        let sheet = workbook_add_worksheet(book, "sheet2")
        var row = 0;
        let title = "无用资源检测报告"
        print("无用数据路径 = \(jsonPath)");
        worksheet_write_string(sheet, lxw_row_t(row), 0, title, nil);
        row+=1
        var numm = 0;
        var totalSize = 0
        for data in kImgDataMap.allValues as NSArray {
            let dict = data as! NSMutableDictionary
            let paths = dict.value(forKey: "data") as! NSArray
            for path in paths {
                result.add(path)
                worksheet_write_string(sheet, lxw_row_t(row), 0, "图片序号\(numm)", nil);
                worksheet_write_string(sheet, lxw_row_t(row), 1,"\((path as? NSDictionary)?.object(forKey: "path") ?? "")", nil);
                row+=1;
                let filePath = ((path as? NSDictionary)?.object(forKey: "path") ?? "") as! String
                if (FileManager.default.fileExists(atPath: filePath)) {
                    let b:[FileAttributeKey : Any] = try! FileManager.default.attributesOfItem(atPath: filePath)
                    let size = b[FileAttributeKey.size] as! Int
                    totalSize+=size
                }
            }
            numm+=1;
        }
        workbook_close(book);
        DispatchQueue.main.async {
            let alert = NSAlert.init()
            alert.messageText = title
            let sizeStr = self.formatSize(size: UInt64(totalSize))
            alert.informativeText = ("共有 \(row-numm-1) 个疑似无用资源\n预期优化空间:\(sizeStr)\n报告路径:\n\(jsonPath)")
            alert.addButton(withTitle: "打开")
            alert.addButton(withTitle: "取消")
            alert.alertStyle = .warning
            alert.beginSheetModal(for: NSApplication.shared.windows[0]) { (modalResponse) in
                if (modalResponse == .alertFirstButtonReturn) {
                    NSWorkspace.shared.openFile(jsonPath)
                }
            }
        }
        callBack(result)
        return result
    }
    func startCheckMD5Files()->NSMutableDictionary!{
        let tmpMd5Map = md5Map.copy()
        for key in (tmpMd5Map as! NSDictionary).allKeys {
            let arr = md5Map.object(forKey: key) as! NSMutableArray
            if (arr.count == 1) {
                md5Map.removeObject(forKey: key)
            }
        }
//        print("\(md5Map)")
        return md5Map
    }
    //格式化 size
    func formatSize(size:UInt64) -> String {
        var result = ""
        let a1 = "\(size)"
        let dba = NSString.init(string: a1).doubleValue
        if (dba < 1024.0) {
            result = String(format: "%.2f字节", dba)
        } else if (dba >= 1024 && dba < 1024*1024.0){
            let a = dba/1024.0
            result = String(format: "%.2fKB", a)
        } else {
            let a = dba/1024.0/1024.0
            result = String(format: "%.2fM", a)
        }
        return result
    }
}



extension MitChecker {
    public func md5(strs:String) ->String!{
        let str = strs.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(strs.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deinitialize(count: digestLen)
        return String(format: hash as String)
    }
    func md5File(filePath:String)->String {
        let bufferSize = 1024*1024
        var result = ""
        do {
            let file = try FileHandle.init(forReadingFrom: URL.init(fileURLWithPath: filePath))
            defer {
                file.closeFile()
            }
            
            var context = CC_MD5_CTX.init()
            CC_MD5_Init(&context)
            while case let data = file.readData(ofLength: bufferSize), data.count > 0 {
                data.withUnsafeBytes { (poiner) -> Void in
                    _ = CC_MD5_Update(&context, poiner, CC_LONG(data.count))
                }
            }
            
            // 计算MD5摘要
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes { (pointer) -> Void in
                _ = CC_MD5_Final(pointer, &context)
            }
            result = digest.map { (byte) -> String in
                String.init(format: "%02hhx", byte)
                }.joined()
//            print("path: \(filePath) result: \(result)")
        } catch {
            print("计算出错") // 哪里try了，就是哪里出错了
        }
        return result
    }
}
