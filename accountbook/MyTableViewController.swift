//
//  MyTableViewController.swift
//  accountbook
//
//  Created by huangyuhsin on 2018/12/12.
//  Copyright © 2018 huangyuhsin All rights reserved.
//

import UIKit
import  SQLite3

class MyTableViewController: UITableViewController {
    var db:OpaquePointer?
    var table: UITableView!
    var dicRow = [String:Any?]()
    var arrTable = [[String:Any?]]()
    var currentRow = 0
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            db = delegate.db
        }
        getDataFromTable()
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
         self.navigationItem.title = "帳本"
    }
     override func prepare(for segue: UIStoryboardSegue, sender: Any?)
     {
     super.prepare(for: segue, sender: sender)
     let detailVC = segue.destination as!DetailViewController
        detailVC.myTableViewController = self
     }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    
    //MARK:- 自訂函式
    @objc func btnEditAction()
    {
        if !self.table.isEditing
        {
            self.table.isEditing = true
            self.navigationItem.leftBarButtonItem?.title = "完成"
        }else{
            self.table.isEditing = false
            self.navigationItem.leftBarButtonItem?.title = "編輯"
        }
        
    }
    
    @objc func handleRefresh()
    {
       getDataFromTable()
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    func getDataFromTable()
    {
        arrTable.removeAll()
        currentRow = 0
        
        if db != nil
        {
            let sql = "select time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo from account order by shoppingdate"
            let cSql = sql.cString(using: .utf8)!
            var statement: OpaquePointer?
            sqlite3_prepare_v3(db, cSql, -1, 0, &statement, nil)
            while sqlite3_step(statement) == SQLITE_ROW
            {
                dicRow.removeAll()
                let time = sqlite3_column_text(statement, 0)
                let strTime = String(cString: time!)
                dicRow["time"] = strTime
                let shoppingdate = sqlite3_column_text(statement, 1)
                let strDate = String(cString: shoppingdate!)
                dicRow["shoppingdate"] = strDate
                let shoppingitem = sqlite3_column_text(statement, 2)
                let stritem = String(cString: shoppingitem!)
                dicRow["shoppingitem"] = stritem
                let shoppingamount = sqlite3_column_int(statement, 3)
                dicRow["shoppingamount"] = Int(shoppingamount)
                 let shoppingtype = sqlite3_column_text(statement, 4)
                 let strtype = String(cString: shoppingtype!)
                 dicRow["shoppingtype"] = strtype
                 let memo = sqlite3_column_text(statement, 5)
                 let strMemo = String(cString: memo!)
                 dicRow["memo"] = strMemo
                arrTable.append(dicRow)
            }
            sqlite3_finalize(statement)
          tableView.reloadData()
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return arrTable.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell
        var currDic = arrTable[indexPath.row]
        cell.lblItem.text = currDic["shoppingitem"] as? String
        cell.lblDate.text = currDic["shoppingdate"] as? String
        
        cell.lblAmount.text = "\(currDic["shoppingamount"] as! Int)"
        return cell
    }
    
    //MARK: － Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        currentRow = indexPath.row
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "刪除") { (rowAction, indexPath) in
            let sql = "delete from account where shoppingdate = '\(self.arrTable[indexPath.row]["shoppingdate"]! as! String )'"
            let cSQL = sql.cString(using: .utf8)
            var statement:OpaquePointer?
            sqlite3_prepare_v3(self.db, cSQL, -1, 0, &statement, nil)
            if sqlite3_step(statement) == SQLITE_DONE
            {
                let alert = UIAlertController(title: "資料庫訊息", message: "資料庫資料已刪除!", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "確定", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            sqlite3_finalize(statement)
            self.tableView.reloadData()
            self.arrTable.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
        
        
        return [deleteAction]
        
    }
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath)
    {
        let tmp = arrTable[fromIndexPath.row]
        arrTable.remove(at: fromIndexPath.row)
        arrTable.insert(tmp, at: to.row)
    }
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
}
