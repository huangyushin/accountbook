//
//  PieChartsViewController.swift
//  accountbook
//
//  Created by huangyuhsin on 2018/12/12.
//  Copyright © 2018 huangyuhsin All rights reserved.
//

import UIKit
import Charts
import SQLite3

class PieChartsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource
{
    
    //宣告資料庫連線指標
    @IBOutlet weak var pieChart: PieChartView!
    @IBOutlet weak var lblTotal: UILabel!
    @IBOutlet weak var tableA: UITableView!
    
    var arrRemark = [String]()
    var arrPoint = [Double]()
    
    var db:OpaquePointer?   //存放資料庫連線的資料
    //記錄單一資料行
    var dicRow = [String:Any?]()
    //紀錄查詢到的資料表，用陣列的形式記錄起來（離線資料集）
    var arrTableA = [[String:Any?]]()
    //目前被點選資料列
    var currentRow = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableA.delegate = self
        tableA.dataSource = self
        //pieChart.noDataText = "You need to provide data for the chart."
        //===================資料庫相關程式====================================
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            //由應用程式代理的實體，取得資料庫連線
            db = delegate.db
        }
        //==================================================================
        //查詢資料存放到離線資料集
        getData()
        //print(getData())
        setChart(dataPoints: arrRemark, values: arrPoint)
        self.view.addSubview(pieChart)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //===================================================================
    // MARK: - Table view data source
    //表格有幾段
    func numberOfSections(in tableView: UITableView) -> Int
    {
        //表個只有一段（不分段的意思）
        return 1
    }
    //每一段表格裡要有幾行資料(只決定數量，不決定內容)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //print("請告知目前表格第\(section)段共有幾列資料")
        return arrTableA.count
    }
    //準備每一個儲存格
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PieChartsViewCell", for: indexPath) as! PieChartsViewCell  //必須先轉型才點得到下面的
        //確定要從哪一種陣列調出當筆資料
        //var currDic = [String:Any?]()
        var currDic = arrTableA[indexPath.row]
        
        //取得儲存格上顯示的資料
        cell.lblItem.text = currDic["shoppingitem"] as? String
        cell.lblDate.text = currDic["shoppingdate"] as? String
        cell.lblAmount.text = "$\(currDic["shoppingamount"] as! Int)"
        
        //回傳準備好的儲存格
        return cell
    }
    
    
    /*var Total = 0
     var s = 1
     
     override func viewWillAppear(_ animated: Bool) {
     super.viewWillAppear(animated)
     
     
     var t = 0
     for t in arrPoint{
     Total += t.amount
     
     for c in arrRemark{
     if(e.arrRemark == c){
     values[t] += Double(e.amount)
     break
     }
     t += 1
     }
     }
     totalLabel.text = "$\(Total)"
     
     setChart()
     
     cell()
     }*/
    
    func setChart(dataPoints:[String],values:[Double])
    {
        
        var dataEntries: [PieChartDataEntry] = []
        
        for i in 0..<dataPoints.count
        {
            let dataEntry = PieChartDataEntry(value: arrPoint[i], label:"\(arrRemark[i])")
            
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(values: dataEntries, label: "")
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        pieChartDataSet.sliceSpace = 2.0
        
        pieChartDataSet.xValuePosition = PieChartDataSet.ValuePosition.outsideSlice
        pieChartDataSet.yValuePosition = PieChartDataSet.ValuePosition.outsideSlice
        pieChart.legend.enabled = false
        
        
        pieChartData.setValueFont(UIFont.systemFont(ofSize: 14))
        pieChartData.setValueTextColor(UIColor(displayP3Red: 0/255, green: 0/255, blue: 0/255, alpha: 1))
        pieChart.data = pieChartData
        var colors:[UIColor] = []
        for _ in 0..<dataPoints.count
        {
            colors.append(UIColor(displayP3Red: CGFloat(Float.random(in: 0.5...1)), green:  CGFloat(Float.random(in: 0...0.5)), blue:  CGFloat(Float.random(in: 0...1)), alpha: 0.5))
        }
        pieChartDataSet.colors = colors
        
        
        
        pieChart.isUserInteractionEnabled = true
        pieChart .setExtraOffsets(left: 0, top: 10, right: 0, bottom: 10)
        pieChart.usePercentValuesEnabled = true
        pieChartData.setValueFormatter(DigitValueFormatter())
        class DigitValueFormatter: NSObject, IValueFormatter
        {
            func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String
            {
                let valueWithoutDecimalPart = String(format: "%.0f%%", value)
                return valueWithoutDecimalPart
            }
        }
        
        
    }
    
    
    
    func getData()
    {
        //先清空陣列
        arrTableA.removeAll()
        //將目前資料列指標歸零
        currentRow = 0
        
        if db != nil
        {
            let sql = "select time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo from account order by time"
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
                
                print("====111====")
                print(strTime)
                print("====111====")
                
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
                
                print("====222====")
                print(stritem)
                //將第2欄存入字典
                dicRow["shoppingitem"] = stritem
                print("購買項目：\(stritem)")
                print("====222====")
                //讀取第3欄
                let shoppingamount = sqlite3_column_int(statement, 3)
                //將第3欄存入字典
                dicRow["shoppingamount"] = Int(shoppingamount)
                
                
                print("====333====")
                print("~~~~~~~購買項目：\(stritem),購買金額:\(Int(shoppingamount))")
                print("====333====")
                
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
                print("====memo====")
                print("當筆字典：\(dicRow)")
                print("====memo====")
                //將當筆字典存入陣列
                arrTableA.append(dicRow)
            }// while 迴圈結尾
            print("====*********====")
            print("從資料庫取得的離線資料集：arrTable\(arrTableA)")
            print("====*********====")
            sqlite3_finalize(statement)
            tableA.reloadData()
        }
        for item in arrTableA
        {
            arrRemark.append(item["shoppingitem"]! as! String)
            arrPoint.append(Double(item["shoppingamount"]! as! Int))
            print("====LELELELEE====")
            print(arrRemark)
            print(arrPoint)
            print("=====LELELELE===")
        }
    }
}



