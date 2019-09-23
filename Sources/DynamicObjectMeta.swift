//
//  DynamicObjectMeta.swift
//  CoreStore iOS
//
//  Created by John Estropia on 2019/08/20.
//  Copyright © 2019 John Rommel Estropia. All rights reserved.
//

import CoreData
import Foundation


// MARK: - DynamicObjectMeta

@dynamicMemberLookup
public struct DynamicObjectMeta<P, R, D>: CustomDebugStringConvertible {

    // MARK: Public
    
    public typealias Path = P
    public typealias Root = R
    public typealias Destination = D

    
    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {

        return self.keyPathString
    }


    // MARK: Internal

    internal let keyPathString: KeyPathString
    
    internal init(root: Void) {
        
        self.keyPathString = "SELF"
    }

    internal init(keyPathString: KeyPathString) {

        self.keyPathString = keyPathString
    }

    internal func appending<D2>(keyPathString: KeyPathString) -> DynamicObjectMeta<(P, D2), R, D2> {

        if self.keyPathString == "SELF" {
            
            return .init(keyPathString: keyPathString)
        }
        return .init(keyPathString: [self.keyPathString, keyPathString].joined(separator: "."))
    }
}


//// MARK: - DynamicObjectMeta where Destination: NSManagedObject
//
//extension DynamicObjectMeta where Destination: NSManagedObject {
//
//    /**
//     Returns the value for the property identified by a given key.
//     */
//    public subscript<V: AllowedObjectiveCAttributeKeyPathValue>(dynamicMember member: KeyPath<Destination, V>) -> DynamicObjectMeta<(Root, Destination), V.ReturnValueType> {
//
//        let keyPathString = String(keyPath: member)
//        return self.appending(keyPathString: keyPathString)
//    }
//
//    /**
//     Returns the value for the property identified by a given key.
//     */
//    public subscript<V: NSManagedObject>(dynamicMember member: KeyPath<Destination, V>) -> DynamicObjectMeta<(Root, Destination), V> {
//
//        let keyPathString = String(keyPath: member)
//        return self.appending(keyPathString: keyPathString)
//    }
//
//    /**
//     Returns the value for the property identified by a given key.
//     */
//    public subscript<V: NSManagedObject>(dynamicMember member: KeyPath<Destination, V?>) -> DynamicObjectMeta<(Root, Destination), V> {
//
//        // TODO: not working
//        let keyPathString = String(keyPath: member)
//        return self.appending(keyPathString: keyPathString)
//    }
//
//    /**
//     Returns the value for the property identified by a given key.
//     */
//    public subscript<V: NSOrderedSet>(dynamicMember member: KeyPath<Destination, V>) -> DynamicObjectMeta<(Root, Destination), V> {
//
//        let keyPathString = String(keyPath: member)
//        return self.appending(keyPathString: keyPathString)
//    }
//
//    /**
//     Returns the value for the property identified by a given key.
//     */
//    public subscript<V: NSOrderedSet>(dynamicMember member: KeyPath<Destination, V?>) -> DynamicObjectMeta<(Root, Destination), V> {
//
//        let keyPathString = String(keyPath: member)
//        return self.appending(keyPathString: keyPathString)
//    }
//
//    /**
//     Returns the value for the property identified by a given key.
//     */
//    public subscript<V: NSSet>(dynamicMember member: KeyPath<Destination, V>) -> DynamicObjectMeta<(Root, Destination), V> {
//
//        let keyPathString = String(keyPath: member)
//        return self.appending(keyPathString: keyPathString)
//    }
//
//    /**
//     Returns the value for the property identified by a given key.
//     */
//    public subscript<V: NSSet>(dynamicMember member: KeyPath<Destination, V?>) -> DynamicObjectMeta<(Root, Destination), V> {
//
//        let keyPathString = String(keyPath: member)
//        return self.appending(keyPathString: keyPathString)
//    }
//}


// MARK: - DynamicObjectMeta where Destination: CoreStoreObject

extension DynamicObjectMeta where Destination: CoreStoreObject {

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<K: AttributeKeyPathStringConvertible>(dynamicMember member: KeyPath<Destination, K>) -> DynamicObjectMeta<(Path, K.ReturnValueType), Root, K.ReturnValueType> {

        let keyPathString = String(keyPath: member)
        return self.appending(keyPathString: keyPathString)
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<K: RelationshipKeyPathStringConvertible>(dynamicMember member: KeyPath<Destination, K>) -> DynamicObjectMeta<(Path, K.DestinationValueType), Root, K.DestinationValueType> {

        let keyPathString = String(keyPath: member)
        return self.appending(keyPathString: keyPathString)
    }
}
