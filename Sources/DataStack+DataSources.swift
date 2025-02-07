//
//  DataStack+DataSources.swift
//  CoreStore iOS
//
//  Copyright © 2018 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if canImport(UIKit) || canImport(AppKit)

import Foundation
import CoreData


// MARK: - DataStack

extension DataStack {
    
    /**
     Creates an `ObjectPublisher` for the specified `DynamicObject`. Multiple objects may then register themselves to be notified when changes are made to the `DynamicObject`.
     
     - parameter object: the `DynamicObject` to observe changes from
     - returns: an `ObjectPublisher` that broadcasts changes to `object`
     */
    public func objectPublisher<O: DynamicObject>(_ object: O) -> ObjectPublisher<O> {

        return ObjectPublisher<O>(objectID: object.cs_id(), context: self.unsafeContext())
    }
    
    /**
     Creates a `ListPublisher` for the specified `From` and `FetchClause`s. Multiple objects may then register themselves to be notified when changes are made to the fetched results.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListPublisher` that broadcasts changes to the fetched results
     */
    public func listPublisher<O>(_ from: From<O>, _ fetchClauses: FetchClause...) -> ListPublisher<O> {

        return self.listPublisher(from, fetchClauses)
    }
    
    /**
     Creates a `ListPublisher` for the specified `From` and `FetchClause`s. Multiple objects may then register themselves to be notified when changes are made to the fetched results.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListPublisher` that broadcasts changes to the fetched results
     */
    public func listPublisher<O>(_ from: From<O>, _ fetchClauses: [FetchClause]) -> ListPublisher<O> {

        return ListPublisher(
            dataStack: self,
            from: from,
            sectionBy: nil,
            applyFetchClauses: { fetchRequest in

                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

                Internals.assert(
                    fetchRequest.sortDescriptors?.isEmpty == false,
                    "An \(Internals.typeName(ListPublisher<O>.self)) requires a sort information. Specify from a \(Internals.typeName(OrderBy<O>.self)) clause or any custom \(Internals.typeName(FetchClause.self)) that provides a sort descriptor."
                )
            }
        )
    }
    
    /**
     Creates a `ListPublisher` that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let listPublisher = dataStack.listPublisher(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     Multiple objects may then register themselves to be notified when changes are made to the fetched results.
     ```
     listPublisher.addObserver(self) { (listPublisher) in
         // handle changes
     }
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: a `ListPublisher` that broadcasts changes to the fetched results
     */
    public func listPublisher<B: FetchChainableBuilderType>(_ clauseChain: B) -> ListPublisher<B.ObjectType> {

        return self.listPublisher(
            clauseChain.from,
            clauseChain.fetchClauses
        )
    }
    
    /**
     Creates a `ListPublisher` for a sectioned list that satisfy the fetch clauses. Multiple objects may then register themselves to be notified when changes are made to the fetched results.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections.
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListPublisher` that broadcasts changes to the fetched results
     */
    public func listPublisher<O>(_ from: From<O>, _ sectionBy: SectionBy<O>, _ fetchClauses: FetchClause...) -> ListPublisher<O> {

        return self.listPublisher(
            from,
            sectionBy,
            fetchClauses
        )
    }
    
    /**
     Creates a `ListPublisher` for a sectioned list that satisfy the fetch clauses. Multiple objects may then register themselves to be notified when changes are made to the fetched results.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections.
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListPublisher` that broadcasts changes to the fetched results
     */
    public func listPublisher<O>(_ from: From<O>, _ sectionBy: SectionBy<O>, _ fetchClauses: [FetchClause]) -> ListPublisher<O> {

        return ListPublisher(
            dataStack: self,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: { fetchRequest in

                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

                Internals.assert(
                    fetchRequest.sortDescriptors?.isEmpty == false,
                    "An \(Internals.typeName(ListPublisher<O>.self)) requires a sort information. Specify from a \(Internals.typeName(OrderBy<O>.self)) clause or any custom \(Internals.typeName(FetchClause.self)) that provides a sort descriptor."
                )
            }
        )
    }
    
    /**
     Creates a `ListPublisher` for a sectioned list that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let listPublisher = dataStack.listPublisher(
         From<MyPersonEntity>()
             .sectionBy(\.age, { "\($0!) years old" })
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     Multiple objects may then register themselves to be notified when changes are made to the fetched results.
     ```
     listPublisher.addObserver(self) { (listPublisher) in
         // handle changes
     }
     ```
     - parameter clauseChain: a `SectionMonitorBuilderType` built from a chain of clauses
     - returns: a `ListPublisher` that broadcasts changes to the fetched results
     */
    public func listPublisher<B: SectionMonitorBuilderType>(_ clauseChain: B) -> ListPublisher<B.ObjectType> {

        return self.listPublisher(
            clauseChain.from,
            clauseChain.sectionBy,
            clauseChain.fetchClauses
        )
    }
}

#endif
