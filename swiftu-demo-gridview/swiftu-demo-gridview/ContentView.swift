//
//  ContentView.swift
//  pubsubtest
//
//  Created by Thisura Dodangoda on 10/12/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SecondView()
    }
}

struct SecondView: View{
    let words = "The quick brown fox".components(separatedBy: " ")
    private var viewModel: GridViewModel = GridViewModel(UIScreen.main.bounds.width, spacing: 10.0)
    @State var items: [String] = []
    
    init() {
        self.items = words
    }
    
    private func getRandomWord() -> String{
        let u_i = arc4random_uniform(UInt32(words.count))
        let i = Int(u_i)
        return words[max(0, min(words.count - 1, i))]
    }
    
    var body: some View{
        VStack(content: {
            
            ForEach(items, id: \.self) { (str) in
                ListItem(text: str)
            }
            
            GridView(model: viewModel)
            
            Stepper {
                items.append(getRandomWord())
                let itemModel = GridViewItemModel()
                itemModel.idName = viewModel.gridViewItems.count.description
                viewModel.addItem(itemModel, at: 0)
            } onDecrement: {
                if items.count > 0{
                    items.remove(at: 0)
                }
                
                viewModel.removeItem(0)
            } label: {
                Text("Items in Array, \(items.count)")
            }
            
            Button ("Flip Random State") {
                let itemIndex = Int(arc4random_uniform(UInt32(viewModel.gridViewItems.count)) )
                let item = viewModel.gridViewItems[itemIndex]
                
                print("Before Flipping state of, \(itemIndex), to \(item.viewState)")
                
                switch(item.viewState){
                case .loading: item.viewState = .contentShowing
                default: item.viewState = .loading
                }
                
                print("After Flipping state of, \(itemIndex), to \(item.viewState)")
            }

            
        })
    }
}

struct ListItem: View{
    @State var text: String = ""
    var body: some View {
        Text(text).background(Color.red).foregroundColor(Color.white)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
