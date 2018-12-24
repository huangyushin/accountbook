//
//  AppDelegate.swift
//  accountbook
//
//  Created by huangyuhsin on 2018/12/12.
//  Copyright © 2018 huangyuhsin All rights reserved.
//

import UIKit
import  SQLite3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //宣告資料庫連線指標
    var db:OpaquePointer?   //存放資料庫連線的資料

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //Step 1:取得app的檔案管理員
        let fileManager = FileManager.default
        //Step 2:取得捆包中資料庫檔案的路徑(❗️注意：此路徑的檔案是惟讀，不可寫入資料！)
        let sourceFile = Bundle.main.path(forResource: "accountbook3", ofType: "sqlite3")!
        print("捆包中資料庫檔案的路徑：\(sourceFile)")
        
        //Step 3:取得應用程式的可讀寫路徑(根目錄下的Documentsy 資料夾)
        let destinationFile = NSHomeDirectory() + "/Documents/accountbook3.sqlite3"
        print("應用程式的可讀寫路徑\(destinationFile)")
        //Step 4:從來源路徑將資料庫檔案複製到“App根目錄下的Documents資料夾“
        if !fileManager.fileExists(atPath: destinationFile)//如果檔案不存在才做複製的動作
        {
            //將捆包中的資料庫檔案複製到“App根目錄下的Documents資料夾“
            try! fileManager.copyItem(atPath: sourceFile, toPath: destinationFile)
        }
        //開啟資料庫連線
        if sqlite3_open(destinationFile, &db) == SQLITE_OK
        {
            print("資料庫開啟成功")
        }
        else
        {
            print("資料庫開啟失敗")
            db = nil
        }
        
        
       
        //把Bundle中要頻繁變動的資料檔案，複製一份到HomeDirectory!然後只對HomeDirectory中的副本進行存取上面這種做法也是一般app提供一份文件給APP，然後各個裝在不同手機設備自己使用這份資料的方式
      
        
        
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

