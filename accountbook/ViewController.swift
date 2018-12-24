//
//  ViewController.swift
//  accountbook
//
//  Created by huangyuhsin on 2018/12/12.
//  Copyright © 2018 huangyuhsin All rights reserved.
//

import UIKit
import Foundation
import SQLite3

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource,UIScrollViewDelegate {
    
    
    
    var db:OpaquePointer?
    var currentItem = ""
    var currentType = ""
    weak var myTableViewController:MyTableViewController!
    @IBOutlet weak var table: UITableView!
    var dicRow = [String:Any?]()
    var tableArr =  [[String:Any?]]()
    @IBOutlet weak var shoppingDate: UITextField!
    @IBOutlet weak var shoppingMemo: UITextView!
    var viewFrame:CGFloat!
    var datePicker:UIDatePicker!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var shoppingDetail: UIView!
    var checkPoint:CheckPoint = .point
    var valueHasTyping:Bool = false
    var userIsInTyping:Bool = false
    var operating = Operating()
    
    //MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewFrame = self.view.frame.height
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let dateToolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.width, height: 40))
        dateToolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        dateToolBar.barStyle = UIBarStyle.blackTranslucent
        dateToolBar.tintColor = UIColor.white
        dateToolBar.backgroundColor = UIColor.black
        let memoToolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.width, height: 40))
        memoToolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        memoToolBar.barStyle = UIBarStyle.blackTranslucent
        memoToolBar.tintColor = UIColor.white
        memoToolBar.backgroundColor = UIColor.black
        let okBarBtn =  UIBarButtonItem(title: "確定", style: .done, target: self, action: #selector(ViewController.donePressed))
        let doneBarBtn =  UIBarButtonItem(title: "確定", style: .done, target: self, action: #selector(ViewController.donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let selectDateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        selectDateLabel.font = UIFont(name: "System", size: 16)
        selectDateLabel.backgroundColor = UIColor.clear
        selectDateLabel.textColor = UIColor.white
        selectDateLabel.text = "請選擇日期"
        selectDateLabel.textAlignment = NSTextAlignment.center
        var memoToolLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        memoToolLabel.font = UIFont(name: "System", size: 16)
        memoToolLabel.backgroundColor = UIColor.clear
        memoToolLabel.textColor = UIColor.white
        memoToolLabel.text = "✏️我的消費小筆記"
        memoToolLabel.textAlignment = NSTextAlignment.center
        let dateBtn = UIBarButtonItem(customView: selectDateLabel)
        let memoBtn = UIBarButtonItem(customView: memoToolLabel)
        memoToolBar.setItems([memoBtn,flexSpace,doneBarBtn], animated: true)
        dateToolBar.setItems([dateBtn,flexSpace,okBarBtn], animated: true)
        scroll.delegate = self
        scroll.isPagingEnabled = true
        scroll.contentSize = shoppingDetail.frame.size
        table.delegate = self
        table.dataSource = self
        shoppingItem.delegate = self
        shoppingItem.dataSource = self
        shoppingType.delegate = self
        shoppingType.dataSource = self
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = NSLocale(localeIdentifier: "zh_TW") as Locale
        shoppingDate.inputView = datePicker
        shoppingDate.inputAccessoryView = dateToolBar
        shoppingMemo.inputAccessoryView = memoToolBar
        shoppingDate.text = DateFormat(selectDate: Date())
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            db = delegate.db
        }

        getData()
    }
    
    @IBOutlet weak var display: UILabel!
    enum CheckPoint {
        case pointZero
        case pointOne
        case pointTwo
        case pointThree
        case point
    }
    func CheckValue(_ checkValue:Double) {
        var temp = checkValue
        if (round(temp) != temp) {
            temp = checkValue * 10
            if(round(temp) != temp) {
                temp = checkValue * 100
                if(round(temp) != temp) {
                    checkPoint = .pointThree
                    
                } else {
                    checkPoint = .pointTwo }
            } else {
                checkPoint = .pointOne }
        } else {
            checkPoint = .pointZero }
    }
    
    
    var displayValue: Double{
        get{
            if(display != nil ){
                return Double(display.text!)!
            } else {
                return 0
            }
        }
        set{
            if(round(newValue) == newValue){
                display.text = String(Int(newValue))
            }
            else{
                display.text = String(newValue)
            }
            CheckValue(_: newValue)
            switch checkPoint {
            case .pointZero:
                display.text = String(Int(newValue))
            case .pointOne:
                display.text = String(format: "%.1f", (newValue))
            case .pointTwo:
                display.text = String(format: "%.2f", (newValue))
            case .pointThree:
                display.text = String(format: "%.2f", (round(newValue*100)/100))
            default:
                display.text = String(newValue)
            }
        }
    }
    
    @IBAction func pressedNum(_ sender: UIButton) {
        if let pressedNum = sender.currentTitle {
            if display.text!.count <= 8 || !userIsInTyping {
                if (pressedNum == "." && !userIsInTyping) {
                    display.text = "0."
                    userIsInTyping = true
                } else if (pressedNum == "." && display.text!.contains(".")  && userIsInTyping ) {
                    display.text = display.text
                } else if (pressedNum == "." && display.text == "0") {
                    display.text = "0."
                } else {
                    if(userIsInTyping) && display.text != "0" {
                        display.text = display.text! + pressedNum
                    }else{
                        display.text = pressedNum
                        userIsInTyping = true
                    }
                }
            }
            valueHasTyping = true
        }
    }
    
    
    struct Operating {
        var resultValue:Double = 0
        var bindingValue:Double = 0
        var bindingOperate:String = ""
        
        mutating func resulet(_ operate:String ,value secondValue:Double)->Double{
            if(bindingOperate == ""){
                bindingValue = secondValue
                bindingOperate = operate
                resultValue = secondValue
            }
            else{
                switch bindingOperate{
                case "+":
                    resultValue = bindingValue + secondValue
                case "-":
                    resultValue = bindingValue - secondValue
                case "×":
                    resultValue = bindingValue * secondValue
                case "÷":
                    resultValue = bindingValue / secondValue
                default:
                    break
                }
                bindingValue = resultValue
                bindingOperate = operate
            }
            if(operate == "="){
                bindingOperate = ""
            }
            return resultValue
        }
        
        mutating func resetBind(){
            bindingValue = 0
            bindingOperate = ""
        }
    }
    
    
    @IBAction func operate(_ sender: UIButton) {
        if let operate = sender.currentTitle{
            switch operate{
            case "+","-","×","÷","=":
                if(valueHasTyping){
                    displayValue = operating.resulet(operate, value: displayValue)
                    userIsInTyping = false
                    valueHasTyping = false
                } else{
                    operating.bindingOperate = operate
                }
            case "AC":
                displayValue = 0
                operating.resetBind()
                userIsInTyping = false
                valueHasTyping = false
            case "←":
                if display.text!.count >= 2 {
                    display.text!.remove(at: display.text!.index(before: display.text!.endIndex))
                } else {
                    displayValue = 0
                    operating.resetBind()
                    userIsInTyping = false
                    valueHasTyping = false
                }
            default:
                break
            }
        }
    }
    //MARK: - 自定函式
    func getData(){
        if db != nil
        {
            
            let sql = "select time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo from account order by time DESC"
            let cSql = sql.cString(using: .utf8)!

            var statement: OpaquePointer?

            sqlite3_prepare_v3(db, cSql, -1, 0, &statement, nil)

            while sqlite3_step(statement) == SQLITE_ROW
            {
                dicRow.removeAll()
                let time = sqlite3_column_text(statement, 0)
                let strTime = String(cString: time!)
                //將第0欄存入字典
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
                tableArr.append(dicRow)
            }
            sqlite3_finalize(statement)
            table.reloadData()
        }
    }
    @objc func datePickerChanged(datePicker:UIDatePicker) {
        shoppingDate.text = DateFormat(selectDate: datePicker.date)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }

    @objc func keyBoardWillShow(_ sender:Notification){

        if let keyboardHeight = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            UIView.animate(withDuration: 0.5, delay: 0.0, animations: {(self.view.frame.origin.y = 0 - keyboardHeight)}, completion: nil)
            
            
        }
    }
    @objc func keyBoardWillHide(){
        self.view.frame.origin.y = 0
    }
    @IBAction func addbutton(_ sender: UIButton)
    {
        
        if db != nil
        {
         
            var d:Date = Date()
            var time:DateFormatter = DateFormatter()
             time.dateFormat = "YYYY-MM-dd HH:mm:ss"
            var timeCurrent = time.string(from: d)
             let sql = "insert into account(time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo) values ('\(timeCurrent)','\(shoppingDate.text!)','\(currentItem)',\(display.text!),'\(currentType)','\(shoppingMemo.text!)')"
             let cSQL = sql.cString(using: .utf8)
             var statement:OpaquePointer?
             sqlite3_prepare_v3(db, cSQL, -1, 0, &statement, nil)
             if sqlite3_step(statement) == SQLITE_DONE
             {

                let newRow:[String:Any?] = [ "time":timeCurrent,"shoppingdate":shoppingDate.text!,"shoppingitem":"\(currentItem)","shoppingamount":display.text!,"shoppingtype":"\(currentType)","memo":shoppingMemo.text!]
         }
             let alert = UIAlertController(title: "資料庫訊息", message: "資料已新增一筆到資料庫!", preferredStyle: .alert)
             alert.addAction( UIAlertAction(title: "確定", style: .default, handler: nil))
             self.present(alert, animated: true, completion: nil)
             }
        displayValue = 0
    }
    //MARK: TableView處理
    @IBOutlet weak var shoppingItem: UITableView!
    var itemList = ["💄化妝品","🍟外食","👜服飾","💰收入","🍆食品","🚦交通罰單","🍩零食","🍺飲料","🍱外賣","💡日用品","📠辦公用品","🔑房租","🏠房屋貸款","🚌巴士","🚕計程車","🎮娛樂","🛋家具","📷家電","🐶寵物用品","🎁禮物","💈理髮","📱電話費","🖥上網費","📺有線電視費","🔌電費","💦水費","🔥煤氣費","💊醫療","⛽️汽油","🅿️停車費","🚗汽車","🎫收費道路費","📕教育","✈️旅行","💼商務旅行","💪健身","🍼寶寶","📑保險費","","","","",]
    @IBOutlet weak var shoppingType: UITableView!
    
    var typeList = ["💰現金","💳信用卡","🏧轉帳","💸其他"]
    
    func DateFormat(selectDate:Date)->String {
        //             selectDate = Date()
        var date = DateFormatter()
        date.dateFormat = "YYYYMMdd"
        //            print(date.string(from: selectDate))
        return date.string(from: selectDate)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        switch tableView {
        case shoppingItem:
            return itemList.count
        case shoppingType:
            return typeList.count
        case table:
         
            return 3
        default:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == shoppingItem
        {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "ItemCell")
            cell.textLabel!.text = "\(itemList[indexPath.row])"
            return cell
        } else if tableView == shoppingType {
            let cell: UITableViewCell =  UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "TypeCell")
            
            cell.textLabel!.text = "\(typeList[indexPath.row])"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountlistCell", for: indexPath) as! accountlistCell
            var currDic = tableArr[indexPath.row]
            cell.lblItem2.text = currDic["shoppingitem"] as? String
            cell.lblDate2.text = currDic["shoppingdate"] as? String
            cell.lblAmount2.text = "\(currDic["shoppingamount"] as! Int)"
            return cell
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == shoppingItem {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            currentItem = itemList[indexPath.row]
        }else if tableView == shoppingType{
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            currentType = typeList[indexPath.row]
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @objc func donePressed(sender: UIBarButtonItem) {
        
        shoppingDate.resignFirstResponder()
        shoppingMemo.resignFirstResponder()
    }
}

