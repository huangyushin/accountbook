//
//  DetailViewController.swift
//  accountbook
//
//  Created by huangyuhsin on 2018/12/12.
//  Copyright © 2018 huangyuhsin All rights reserved.
//

import UIKit
import SQLite3

class DetailViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate
{
     var datePicker:UIDatePicker!
    @IBOutlet weak var textDate: UITextField!
    
    @IBOutlet weak var textItem: UITextField!
    
    @IBOutlet weak var textAmount: UITextField!
    
    @IBOutlet weak var textType: UITextField!
    
    @IBOutlet weak var textMemo: UITextField!
    var db:OpaquePointer?

    weak var myTableViewController:MyTableViewController!
    var pkvItem:UIPickerView!
    var pkvType:UIPickerView!
    let arrItem =  ["💄化妝品","🍟外食","👜服飾","💰收入","🍆食品","🚦交通罰單","🍩零食","🍺飲料","🍱外賣","💡日用品","📠辦公用品","🔑房租","🏠房屋貸款","🚌巴士","🚕計程車","🎮娛樂","🛋家具","📷家電","🐶寵物用品","🎁禮物","💈理髮","📱電話費","🖥上網費","📺有線電視費","🔌電費","💦水費","🔥煤氣費","💊醫療","⛽️汽油","🅿️停車費","🚗汽車","🎫收費道路費","📕教育","✈️旅行","💼商務旅行","💪健身","🍼寶寶","📑保險費"]
    let arrType = ["💰現金","💳信用卡","🏧轉帳","💸其他"]
    var currentObjectBottonYPosition:CGFloat = 0
    
    //MARK: Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            db = delegate.db
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        var currentData = [String:Any?]()
        
        currentData = myTableViewController.arrTable[myTableViewController.currentRow]
        textDate.text = currentData["shoppingdate"] as? String
        textItem.text = currentData["shoppingitem"] as?String
        textAmount.text = "\( currentData["shoppingamount"] as! Int)"
        textType.text = currentData["shoppingtype"] as? String
        textMemo.text = currentData["memo"] as? String
        pkvItem = UIPickerView()
        pkvItem.tag = 2
        pkvType = UIPickerView()
        pkvType.tag = 4
        pkvItem.dataSource = self
        pkvItem.delegate = self
        pkvType.dataSource = self
        pkvType.delegate = self
        textItem.inputView = pkvItem
        textType.inputView = pkvType
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = NSLocale(localeIdentifier: "zh_TW") as Locale
        textDate.inputView = datePicker
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
       
    }
    // MARK: - 自訂函式
    @objc func keyBoardWillShow(_ sender:Notification)
    {
        if let keyBoardHeight = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height{
            let visiableHeight = self.view.frame.height - keyBoardHeight
            if currentObjectBottonYPosition > visiableHeight
            {
                self.view.frame.origin.y = 0 - (currentObjectBottonYPosition - visiableHeight)
            }
        }
    }
    @objc func keyBoardWillHide()
    {
        self.view.frame.origin.y = 0
    }
    func DateFormat(selectDate:Date)->String {
        var date = DateFormatter()
        date.dateFormat = "YYYYMMdd"
        return date.string(from: selectDate)
    }
    
    // MARK: - 自訂手勢
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }

    @objc func datePickerChanged(datePicker:UIDatePicker) {
        textDate.text = DateFormat(selectDate: datePicker.date)
    }
    
    
    //MAEK: - Target Action

    @IBAction func editDidBegin(_ sender: UITextField)
    {
        currentObjectBottonYPosition = sender.frame.origin.y + sender.frame.size.height
            sender.keyboardType = .default
    }
    
    
    
    // MARK: - 按鈕群
    @IBAction func 更新資料(_ sender: UIButton)
    {
        if db != nil
        {
            let sql = "update account set shoppingitem = '\(textItem.text!)',shoppingamount = '\(textAmount.text!)',shoppingtype = '\(textType.text!)',memo = '\(textMemo.text!)' where shoppingdate = '\(textDate.text!)'"
            let cSQL = sql.cString(using: .utf8)
            var statement:OpaquePointer?
            sqlite3_prepare_v3(db, cSQL, -1, 0, &statement, nil)
            if sqlite3_step(statement) == SQLITE_DONE
            {
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingdate "] = textDate.text
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingitem"] = textItem.text
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingamount"] = textAmount.text
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingtype"] = textType.text
                myTableViewController.arrTable[myTableViewController.currentRow]["memo"] = textMemo.text
                let alert = UIAlertController(title: "資料庫訊息", message: "資料已更新到資料庫!", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "確定", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)

            }
            sqlite3_finalize(statement)
            
            
        }
    }
    
    //MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if pickerView.tag == 2
        {
            return arrItem.count
        }
        else if pickerView.tag == 4
        {
            return arrType.count
        }
        return arrType.count
        
    }
    //MARK:- UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if pickerView.tag == 2
        {
            return arrItem[row]
        }
        else if pickerView.tag == 4
        {
            return arrType[row]
        }
        return arrType[row]
    }
    //當選定滾輪的特定資料列時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch pickerView.tag
        {
        case 2:
            textItem.text = arrItem[row]
        
        default:
            textType.text = arrType[row]
        }
    }
    
    
}
