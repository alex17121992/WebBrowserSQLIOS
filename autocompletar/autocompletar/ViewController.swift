//
//  ViewController.swift
//  autocompletar
//
//  Created by Juan Jimenez Vacas on 27/1/19.
//  Copyright © 2019 Juan Jimenez Vacas. All rights reserved.
//

import UIKit
import SQLite3

class ViewController: UIViewController {

    @IBOutlet weak var countrySearch: UISearchBar!
    
    @IBAction func back(_ sender: Any) {
        if myWebView.canGoBack{
            myWebView.goBack()
        }
    }
    @IBAction func next(_ sender: Any) {
        if myWebView.canGoForward{
            myWebView.goForward()
        }

    }
    @IBAction func refresh(_ sender: Any) {
        myWebView.reload()
    }
    @IBOutlet weak var myWebView: UIWebView!
    @IBOutlet weak var tblView: UITableView!
    var db: OpaquePointer?
    var historial=[Historial]()
    var searchedDireccion = [Historial]()
    var searching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myWebView.loadRequest(URLRequest(url: URL(string:"https://www.google.es")!))
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("direcciones.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        else {
            print("base abierta")
            if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS HISTORIAL (id INTEGER PRIMARY KEY AUTOINCREMENT, direccion TEXT)", nil, nil, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error creating table: \(errmsg)")
            }
        }
        readValues()
    }
}
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchedDireccion.count
        } else {
            return historial.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if searching {
            cell?.textLabel?.text = searchedDireccion[indexPath.row].direcciones
        } else {
            cell?.textLabel?.text = historial[indexPath.row].direcciones
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       let indexPath=tableView.indexPathForSelectedRow
       let currentCell=tableView.cellForRow(at: indexPath!)! as UITableViewCell
       let currentItem=currentCell.textLabel!.text
       countrySearch.text=currentItem
    }
}

extension ViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tblView.isHidden=false
        searchedDireccion = historial.filter({$0.direcciones!.lowercased().prefix(searchText.count) == searchText.lowercased()})
        searching = true
        tblView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        countrySearch.resignFirstResponder()
        if let url=URL(string:countrySearch.text!){
            myWebView.loadRequest(URLRequest(url:url))
            insertar(direccion: countrySearch.text!)
            tblView.isHidden=true
            readValues()
        }else{
            print("Error")
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tblView.isHidden=true
        searching = false
        searchBar.text = ""
        tblView.reloadData()
    }
    
    func insertar(direccion:String)  {
        
        //getting values from textfields
        
        
        
        //creating a statement
        var stmt: OpaquePointer?
        
        //the insert query
        let queryString = "INSERT INTO HISTORIAL (DIRECCION) VALUES ('"+direccion+"')"
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
        
        
        //executing the query to insert values
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure inserting hero: \(errmsg)")
            return
        }
        
        
    }
    
    func readValues(){
        
        
        //this is our select query
        let queryString = "SELECT * FROM HISTORIAL"
        
        //statement pointer
        var stmt:OpaquePointer?
        
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
        
        //traversing through all the records
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let id = sqlite3_column_int(stmt, 0)
            let direcciones = String(cString: sqlite3_column_text(stmt, 1))
            historial.append(Historial(id:Int(id),direcciones:direcciones))
    }

}

class Historial {
    
    var id: Int
    var direcciones: String?
    
    init(id: Int, direcciones: String?){
        self.id = id
        self.direcciones = direcciones
    }
}
}
