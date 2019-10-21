//
//  Internals.DiffableDataUIDispatcher.swift
//  CoreStore
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

import CoreData

#if canImport(QuartzCore)
import QuartzCore

#endif


// MARK: - Internals

extension Internals {

    // MARK: Internal

    // Implementation based on https://github.com/ra1028/DiffableDataSources
    @usableFromInline
    internal final class DiffableDataUIDispatcher<O: DynamicObject> {

        // MARK: Internal
        
        typealias ObjectType = O
        
        init(dataStack: DataStack) {
            
            self.dataStack = dataStack
        }
        
        func apply<View: AnyObject>(_ snapshot: DiffableDataSourceSnapshot, view: View?, animatingDifferences: Bool, performUpdates: @escaping (View, StagedChangeset<[Internals.DiffableDataSourceSnapshot.Section]>, @escaping ([Internals.DiffableDataSourceSnapshot.Section]) -> Void) -> Void) {
            
            self.dispatcher.dispatch { [weak self] in
                
                guard let self = self else {
                    
                    return
                }

                self.currentSnapshot = snapshot

                let newSections = snapshot.sections
                guard let view = view else {
                    
                    return self.sections = newSections
                }

                let performDiffingUpdates: () -> Void = {
                    
                    let changeset = StagedChangeset(source: self.sections, target: newSections)
                    performUpdates(view, changeset) { sections in
                        
                        self.sections = sections
                    }
                }

                #if canImport(QuartzCore)
                
                if !animatingDifferences {
                    
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    
                    performDiffingUpdates()
                    
                    CATransaction.commit()
                    return
                }
                
                #endif
                
                performDiffingUpdates()
            }
        }

        func snapshot() -> DiffableDataSourceSnapshot {
            
            var snapshot: DiffableDataSourceSnapshot = .init()
            snapshot.sections = self.currentSnapshot.sections
            return snapshot
        }

        func itemIdentifier(for indexPath: IndexPath) -> O.ObjectID? {
            
            guard (0 ..< self.sections.endIndex) ~= indexPath.section else {
                
                return nil
            }
            let items = self.sections[indexPath.section].elements
            guard (0 ..< items.endIndex) ~= indexPath.item else {
                
                return nil
            }
            return items[indexPath.item].differenceIdentifier
        }

        func indexPath(for itemIdentifier: O.ObjectID) -> IndexPath? {
            
            let indexPathMap: [O.ObjectID: IndexPath] = self.sections.enumerated().reduce(into: [:]) { result, section in
                
                for (itemIndex, item) in section.element.elements.enumerated() {
                    
                    result[item.differenceIdentifier] = IndexPath(
                        item: itemIndex,
                        section: section.offset
                    )
                }
            }
            return indexPathMap[itemIdentifier]
        }

        func numberOfSections() -> Int {
            
            return self.sections.count
        }

        func numberOfItems(inSection section: Int) -> Int {
            
            return self.sections[section].elements.count
        }
        
        func sectionIdentifier(inSection section: Int) -> String {
            
            return self.sections[section].differenceIdentifier
        }


        // MARK: Private

        private let dispatcher: MainThreadSerialDispatcher = .init()
        private let dataStack: DataStack

        private var currentSnapshot: Internals.DiffableDataSourceSnapshot = .init()
        private var sections: [Internals.DiffableDataSourceSnapshot.Section] = []
        
        
        // MARK: - ElementPath
        
        @usableFromInline
        internal struct ElementPath: Hashable {
            
            @usableFromInline
            var element: Int
            
            @usableFromInline
            var section: Int

            @inlinable
            init(element: Int, section: Int) {
                
                self.element = element
                self.section = section
            }
        }


        // MARK: - MainThreadSerialDispatcher

        fileprivate final class MainThreadSerialDispatcher {

            // MARK: FilePrivate

            fileprivate init() {

                self.executingCount.initialize(to: 0)
            }

            deinit {

                self.executingCount.deinitialize(count: 1)
                self.executingCount.deallocate()
            }

            fileprivate func dispatch(_ action: @escaping () -> Void) {

                let count = OSAtomicIncrement32(self.executingCount)
                if Thread.isMainThread && count == 1 {

                    action()
                    OSAtomicDecrement32(executingCount)
                }
                else {

                    DispatchQueue.main.async { [weak self] in

                        guard let self = self else {

                            return
                        }
                        action()
                        OSAtomicDecrement32(self.executingCount)
                    }
                }
            }


            // MARK: Private

            private let executingCount: UnsafeMutablePointer<Int32> = .allocate(capacity: 1)
        }
        
    }
}

#endif