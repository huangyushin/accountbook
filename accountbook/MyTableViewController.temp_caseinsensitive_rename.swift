//
//  myTableViewController.swift
//  accountbook
//
//  Created by lemonart on 2018/12/10.
//  Copyright © 2018 Lemon. All rights reserved.
//

import UIKit
import  SQLite3

class MyTableViewController: UITableViewController {

   
    //宣告資料庫連線指標
    var db:OpaquePointer?   //存放資料庫連線的資料
    var table: UITableView!
    //記錄單一資料行
    var dicRow = [String:Any?]()
    //紀錄查詢到的資料表，用陣列的形式記錄起來（離線資料集）
    var arrTable = [[String:Any?]]()
    //目前被點選資料列
    var currentRow = 0
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
       tableView.delegate = self
      tableView.dataSource = self
        
        //以下與資料庫相關
        //===================資料庫相關程式====================================
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            //由應用程式代理的實體，取得資料庫連線
            db = delegate.db
        }
        //查詢資料存放到離線資料集
        getDataFromTable()
        // print(getDataFromTable())
       
        //==================================================================
        //準備離線資料集
        /*
         arrTable = [
         ["shoppingdate":"20181210","shoppingitem":"掛號費","shoppingamount":200],
         ["shoppingdate":"20181209","shoppingitem":"午餐費","shoppingamount":80],
         ["shoppingdate":"20181208","shoppingitem":"晚餐費","shoppingamount":200],
         ["shoppingdate":"20181210","shoppingitem":"早餐費","shoppingamount":50]        ]
        */
        
        ////=======設定下拉更新元件==============
        //為表格增加更新元件
        self.tableView.refreshControl = UIRefreshControl()
        //設定下拉更新元件對應的value change事件，與呼叫的函式
        self.tableView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
//        //設定下拉更新元件的文字
//            self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...") as! [[String : Any?]]
        
        
      //  table.reloadData()
        
    }
    //更新資料
     //點選儲存格，即將由換頁線換頁時
     override func prepare(for segue: UIStoryboardSegue, sender: Any?)
     {
     super.prepare(for: segue, sender: sender)
     print("即將由換頁線換頁")
     //取得詳細頁面的執行實體（執行參數傳遞）
     let detailVC = segue.destination as!DetailViewController
     detailVC.myTableViewController = self
     }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        print("畫面即將呈現")
        self.tableView.reloadData()
    }
    
    
    //MARK:- 自訂函式
    //由導覽列的編輯按鈕呼叫
    @objc func btnEditAction()
    {
        if !self.table.isEditing  //如果表格不在編輯狀態
        {
            //就讓表格進入編輯狀態
            self.table.isEditing = true
            //更換按鈕文字
            self.navigationItem.leftBarButtonItem?.title = "完成"
        }else{
            //就讓表格回復到非編輯狀態
            self.table.isEditing = false
            //更換按鈕文字
            self.navigationItem.leftBarButtonItem?.title = "編輯"
            
        }
        
    }
    /*
     //    由導覽列的新增按鈕呼叫
     @objc func btnAddAction()
     {
     
     print("新增按鈕被按下")
     //取得新增畫面實體
     let addVC = self.storyboard!.instantiateViewController(withIdentifier: "AddViewController") as! AddViewController
     //傳遞資訊
     addVC.myTableViewController = self
     
     //顯示新增畫面
     self.show(addVC, sender: nil)
     
     }
     */
    //    由下拉更新元件所觸發的事件
    @objc func handleRefresh()
    {
        
        print("下拉更新")
        
        //step1.重新讀取來源資料庫的資料到離線資料集(arrTable)
       getDataFromTable()
        //step2.更新表格資料
        self.tableView.reloadData()
        //step3.停止下拉更新元件的更新狀態
        self.tableView.refreshControl?.endRefreshing()
        
        
    }
    
    //===================資料庫相關程式====================================
    //查詢資料存放到離線資料集  (由此準備離線資料集)
    func getDataFromTable()
    {
        //先清空陣列
        arrTable.removeAll()
        //將目前資料列指標歸零
        currentRow = 0
        
        if db != nil
        {
            let sql = "select time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo from account order by shoppingdate"
            //將SQL指令由swift的字串，轉換成C語言字串（即字串陣列）
            let cSql = sql.cString(using: .utf8)!
            
            //宣告儲存查詢結果的變數
            var statement: OpaquePointer?
            /*準備查詢
             （第三個參數若為正數，則限定SQL指令的長度，負數則不限定SQL指定的長度，
             第四個參數為預備標誌-prepareFlag，準備給下一版使用，目前沒有作用，其預設為0，（v2版沒有這個參數）
             最後一個參數為預留參數，目前沒有作用）
             */
            
            sqlite3_prepare_v3(db, cSql, -1, 0, &statement, nil)
            //sqlite3_prepare_v2(db, cSql, -1, &statement, nil) -1是不限指令輸入的長度
            //如果可以讀到一筆資料，則執行迴圈
            while sqlite3_step(statement) == SQLITE_ROW
            {
                //先清空字典
                dicRow.removeAll()
                
                let time = sqlite3_column_text(statement, 0)
                //將第0欄資料由Ｃ語言字串，轉換成SWIFT字串
                let strTime = String(cString: time!)
                //將第0欄存入字典
                dicRow["time"] = strTime
                
                //讀取第1欄
                let shoppingdate = sqlite3_column_text(statement, 1)
                //將第1欄資料由Ｃ語言字串，轉換成SWIFT字串
                let strDate = String(cString: shoppingdate!)
                //將第1欄存入字典
                dicRow["shoppingdate"] = strDate
                
                //讀取第2欄
                let shoppingitem = sqlite3_column_text(statement, 2)
                //將第2欄資料由Ｃ語言字串，轉換成SWIFT字串
                let stritem = String(cString: shoppingitem!)
                //將第2欄存入字典
                dicRow["shoppingitem"] = stritem
                
                print("購買時間：\(strDate)，購買項目：\(stritem)")
                
                //讀取第3欄
                let shoppingamount = sqlite3_column_int(statement, 3)
                //將第3欄存入字典
                dicRow["shoppingamount"] = Int(shoppingamount)
                
                print("~~~~~~~購買時間：\(strDate)，購買項目：\(stritem),購買金額:\(Int(shoppingamount))")
                
                
                
                 //讀取第4欄
                 let shoppingtype = sqlite3_column_text(statement, 4)
                 //將第4欄資料由Ｃ語言字串，轉換成SWIFT字串
                 let strtype = String(cString: shoppingtype!)
                 //將第4欄存入字典
                 dicRow["shoppingtype"] = strtype
                 
                 //讀取第5欄
                 let memo = sqlite3_column_text(statement, 5)
                 //將第5欄資料由Ｃ語言字串，轉換成SWIFT字串
                 let strMemo = String(cString: memo!)
                 //將第5欄存入字典
                 dicRow["memo"] = strMemo
                 
                
                
                
                
                print("當筆字典：\(dicRow)")
                //將當筆字典存入陣列
                arrTable.append(dicRow)
            }// while 迴圈結尾
            print("從資料庫取得的離線資料集：arrTable\(arrTable)")
            sqlite3_finalize(statement)
          tableView.reloadData()
        }
    }
    
    
    
    //===================================================================
    // MARK: - Table view data source
    //表格有幾段
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        //表個只有一段（不分段的意思）
        return 1
    }
    //每一段表格裡要有幾行資料(只決定數量，不決定內容)
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        print("請告知目前表格第\(section)段共有幾列資料")
        
        
        
        
        
        return arrTable.count
        /*若有分段，要寫下面程式碼
         switch section {
         case 0:
         return 2
         case 1:
         return 3
         default:
         return4
         }
         */
        
    }
    
    //準備每一個儲存格
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell  //必須先轉型才點得到下面的
        var currDic = arrTable[indexPath.row]
        
        print("currDic目前的數值是～～～～～～\(currDic)")
        /*
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "MyCell")
        cell.textLabel!.text = "\(arrTable[indexPath.row])"
       return cell
 */
        /*
       // let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell  //必須先轉型才點得到下面的
 */
        
       
        
        
        
        
        
        
        //取得儲存格上顯示的資料
        
        
        cell.lblItem.text = currDic["shoppingitem"] as? String
        cell.lblDate.text = currDic["shoppingdate"] as? String
        
        cell.lblAmount.text = "\(currDic["shoppingamount"] as! Int)"
        
 
 
        /*
         // 這是標準儲存格的樣式       //取得儲存格上顯示的資料
         cell.textLabel?.text = arrTable[indexPath.row]["shoppingitem"] as? String
         cell.textLabel?.text = arrTable[indexPath.row]["shoppingamount"] as? String
         cell.detailTextLabel?.text = arrTable[indexPath.row]["shppingdate"] as? String
         cell.accessoryType = .detailButton//表格的樣式
        */
        //回傳準備好的儲存格
        return cell
    }
    
    //MARK: － Table view delegate
    //事件：哪一個儲存格被點擊了
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("第\(indexPath.row)列被點選:\(arrTable[indexPath.row]["time"] as! String)")
        currentRow = indexPath.row
    }
    
    
    //<方法一>訂製向左滑動的右側按鈕，只能使用１個刪除按鈕（包含以下２個事件）
    // 表格提交編輯狀態時（包含刪除和新增 ps.通常新增用不到，所以現在註解掉）
    //注意：此事件同時提供向左滑動刪除的功能
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            //Step1.實際刪除資料庫當筆資料
            //－－－－－－－－to do------------
            //Step2.刪除離線資料庫（陣列）的當筆資料
            arrTable.remove(at: indexPath.row)
            //Step3. 刪除表格上的儲存格
            table.deleteRows(at: [indexPath], with: .fade)//🔴在[indexPath] 修改可以一次刪除多筆
            
        }
        //         else if editingStyle == .insert
        //         {
        //             // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        //         }
    }
    //更換刪除按鈕的文字
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    {
        return "不要了！"
    }
    //<方法二>訂製向左滑動的右側按鈕，可以使用兩個以上的按鈕
    //回傳儲存格向左滑動時的右側按鈕”陣列“ （做２個左滑按鈕）
    //⭐️❗️注意：若加了這個方法（函式），前兩個方法（函式）會失效❗️⭐️
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let moreAction = UITableViewRowAction(style: .normal, title: "更多") { (rowAction, indexPath) in
            print("更多按鈕被按下！")
        }
        let deleteAction = UITableViewRowAction(style: .destructive, title: "刪除") { (rowAction, indexPath) in
            print("刪除按鈕被按下！")
            //Step1.實際刪除資料庫當筆資料
            //Step1-1:準備SQL指令
            let sql = "delete from student where stu_no = '\(self.arrTable[indexPath.row]["no"]! as! String )'"
            //將ＳＱＬ指令轉成Ｃ語言字串
            let cSQL = sql.cString(using: .utf8)
            //宣告儲存指令結果的指令
            var statement:OpaquePointer?
            /*
             Step1-2:準備查詢
             （第三個參數若為正數，則限定SQL指令的長度，負數則不限定SQL指定的長度，
             第四個參數為預備標誌-prepareFlag，準備給下一版使用，目前沒有作用，其預設為0，（v2版沒有這個參數）
             最後一個參數為預留參數，目前沒有作用）
             */
            sqlite3_prepare_v3(self.db, cSQL, -1, 0, &statement, nil)
            //Step1-3:準備執行ＳＱＬ指令
            if sqlite3_step(statement) == SQLITE_DONE
            {
                //製作彈出訊息視窗
                let alert = UIAlertController(title: "資料庫訊息", message: "資料庫資料已刪除!", preferredStyle: .alert)
                //在彈出訊息的視窗加上一顆按鈕
                alert.addAction( UIAlertAction(title: "確定", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            //Step1-4: 關閉SQL連線指令
            sqlite3_finalize(statement)
            self.tableView.reloadData()
            
            
            
            //Step2.刪除離線資料庫（陣列）的當筆資料
            self.arrTable.remove(at: indexPath.row)
            //Step3. 刪除表格上的儲存格
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        
        return [moreAction,deleteAction]
        
    }
    
    
    
    
    
    
    
    
    
    
    //注意：移動儲存格相關功能，必須同時實作以下兩個事件
    //實際移動儲存格時會執行這個方法（函式）（出現可移動的３條橫線）
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath)
    {
        //Step1.交換對應的陣列元素
        //Step1-1.紀錄目前點擊之處所在的陣列元素
        let tmp = arrTable[fromIndexPath.row]
        //Step1-2.移除目前點擊之處所在的陣列元素
        arrTable.remove(at: fromIndexPath.row)
        //Step1-3.將記憶的陣列元素，安插到最放開的位置
        arrTable.insert(tmp, at: to.row)
        
        print("移動後的陣列:\(arrTable)")
        
        
        //Strp2.回寫至離線資料庫的順序
    }
    
    
    
    // 允許儲存格可以拖曳來交換順序
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
    {
        
        return true
    }
    
}
