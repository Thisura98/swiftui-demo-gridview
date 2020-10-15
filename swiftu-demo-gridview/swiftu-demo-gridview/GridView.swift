//
//  GridView.swift
//  A grid that shows content, which can be lazily loaded.
//
//  Created by Thisura Dodangoda on 10/15/20.
//

import SwiftUI
import Foundation

/*
 Module Architecture
 
 GridView: 1 <--layout information-- GridViewModel
 |
  -- GridViewItem: [0..n] <--layout information-- GridViewItemModel
 */


class GridViewModel: ObservableObject{
    
    var gridViewItems: [GridViewItemModel] = []
    private var currentProcessingOperation: DispatchWorkItem?
    private var viewRenderingSize: CGSize = .zero
    
    private var initComplete: Bool = false
    
    var galleryViewWidth: CGFloat = 100.0{
        didSet{ setNeedsViewUpdate(); }
    }
    var spacing: CGFloat = 10.0{
        didSet { setNeedsViewUpdate(); }
    }
    /**
     Width of one item
     */
    var itemViewWidth: CGFloat = 20.0
    /**
     Spacing between items
     */
    var columns: Int = 3 {
        didSet{
            setNeedsViewUpdate()
        }
    }
    
    @Published var vStacksCount: Int = 0
    @Published var vStackIndexHalfFilled: Int = 0
    @Published var vStackHalfFilledItemCount: Int = 0
    
    init(_ galleryViewWidth: CGFloat, spacing: CGFloat){
        self.galleryViewWidth = galleryViewWidth
        self.spacing = spacing
        
        for i in 0..<8{
            let item = GridViewItemModel()
            item.idName = i.description
            gridViewItems.append(item)
        }
        
        initComplete = true
        setNeedsViewUpdate()
    }
    
    private func processItems(){
        if let currentOperation = currentProcessingOperation{
            currentOperation.cancel()
            dispatchWorkItemCleanup()
        }
        
        currentProcessingOperation = DispatchWorkItem(qos: .background, flags: [], block: { [weak self] in
            guard let s = self else { return }
            guard s.gridViewItems.count > 0 else { return }
            
            let spacingWidth = (CGFloat(s.columns - 1) * s.spacing)
            s.itemViewWidth = (s.galleryViewWidth - (spacingWidth)) / CGFloat(s.columns)
            
            let divResult = s.gridViewItems.count.quotientAndRemainder(dividingBy: s.columns)
            let vStacksCount = divResult.quotient + (divResult.remainder > 0 ? 1 : 0)
            var vStackIndexHalfFilled = -1
            var vStackHalfFilledItemCount = 0
            
            if divResult.remainder > 0{
                vStackIndexHalfFilled = divResult.quotient
                vStackHalfFilledItemCount = divResult.remainder
            }
            
            DispatchQueue.main.async{ [weak self] in
                self?.vStackIndexHalfFilled = vStackIndexHalfFilled
                self?.vStacksCount = vStacksCount
                self?.vStackHalfFilledItemCount = vStackHalfFilledItemCount
                self?.dispatchWorkItemCleanup()
            }
        })
        
        DispatchQueue.global().async(execute: currentProcessingOperation!)
    }
    
    private func dispatchWorkItemCleanup(){
        currentProcessingOperation = nil
    }
    
    private func setNeedsViewUpdate(){
        guard initComplete else { return }
        // todo
        // processItems on background thread and then set needsViewRebuild
        //needsViewRebuild = true
        processItems()
    }
    
    fileprivate func getItem(atRow: Int, column: Int) -> GridViewItemModel?{
        var index = max(0, atRow * columns)
        index += column
        if index < gridViewItems.count{
            return gridViewItems[index]
        }
        else{
            return nil
        }
    }
    
    func addItem(_ item: GridViewItemModel, at: Int){
        if at < gridViewItems.count{
            gridViewItems.insert(item, at: at)
        }
        else{
            gridViewItems.append(item)
        }
        setNeedsViewUpdate()
    }
    
    @discardableResult
    func removeItem(_ at: Int) -> GridViewItemModel?{
        var result: GridViewItemModel?
        if at < gridViewItems.count{
            result = gridViewItems.remove(at: at)
        }
        else{
            result = gridViewItems.popLast()
        }
        
        if result != nil{
            setNeedsViewUpdate()
        }
        
        return result
    }
}

class GridViewItemModel: ObservableObject{
    enum ViewState{
        case loading, noContent, contentShowing
    }
    @Published var viewState: ViewState = .loading
    @Published var idName: String = "unk"
    init(){
        
    }
}

struct GridView: View{
    @ObservedObject var model: GridViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(0..<model.vStacksCount, id: \.self){ (i: Int) in
                    HStack(spacing: model.spacing / 2.0) {
                        if (model.vStackIndexHalfFilled == i){
                            ForEach(0..<model.vStackHalfFilledItemCount, id: \.self){ (j: Int) in
                                if let item = model.getItem(atRow: i, column: j){
                                    GridViewItem(model: item).frame(width: model.itemViewWidth, height: model.itemViewWidth)
                                }
                                else{
                                    EmptyView()
                                }
                            }
                            //Text("Wow am half filled model Row: \(i), with \(model.vStackHalfFilledItemCount) items")
                        }
                        else{
                            ForEach(0..<model.columns, id: \.self){ (j: Int) in
                                if let item = model.getItem(atRow: i, column: j){
                                    GridViewItem(model: item).frame(width: model.itemViewWidth, height: model.itemViewWidth)
                                }
                                else{
                                    EmptyView()
                                }
                            }
                            //Text("Wow am filled model Row: \(i), with \(model.columns) items")
                        }
                    }.frame(maxWidth: .infinity).background(Color.orange)
                }
            }.frame(maxWidth: .infinity).background(Color.red)
        }
    }
}

struct GridViewItem: View{
    
    @ObservedObject var model: GridViewItemModel
    
    var body: some View {
        VStack {
            Text(model.idName).background(Color.purple)
            switch(model.viewState){
            case .loading:
                ProgressView().background(Color.green)
                //Text("Loading...").background(Color.green)
            case .noContent:
                Text("No Contnet")
            case .contentShowing:
                Text("Yay!")
            }
        }
    }
}
