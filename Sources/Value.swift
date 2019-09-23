//
//  Value.swift
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

import CoreData
import Foundation


// MARK: - DynamicObject

extension DynamicObject where Self: CoreStoreObject {
    
    /**
     The containing type for value propertiess. `Value` properties support any type that conforms to `ImportableAttributeType`.
     ```
     class Animal: CoreStoreObject {
         let species = Value.Required<String>("species", initial: "")
         let nickname = Value.Optional<String>("nickname")
         let color = Transformable.Optional<UIColor>("color")
     }
     ```
     - Important: `Value` properties are required to be stored properties. Computed properties will be ignored, including `lazy` and `weak` properties.
     */
    public typealias Value = ValueContainer<Self>
}


// MARK: - ValueContainer

/**
 The containing type for value properties. Use the `DynamicObject.Value` typealias instead for shorter syntax.
 ```
 class Animal: CoreStoreObject {
     let species = Value.Required<String>("species", initial: "")
     let nickname = Value.Optional<String>("nickname")
     let color = Transformable.Optional<UIColor>("color")
 }
 ```
 */
public enum ValueContainer<O: CoreStoreObject> {
    
    // MARK: - Required
    
    /**
     The containing type for required value properties. Any type that conforms to `ImportableAttributeType` are supported.
     ```
     class Animal: CoreStoreObject {
         let species = Value.Required<String>("species", initial: "")
         let nickname = Value.Optional<String>("nickname")
         let color = Transformable.Optional<UIColor>("color")
     }
     ```
     - Important: `Value.Required` properties are required to be stored properties. Computed properties will be ignored, including `lazy` and `weak` properties.
     */
    @propertyWrapper
    public final class Required<V: ImportableAttributeType>: AttributeKeyPathStringConvertible, AttributeProtocol {
        
        /**
         Initializes the metadata for the property.
         ```
         class Person: CoreStoreObject {
             let title = Value.Required<String>("title", initial: "Mr.")
             let name = Value.Required<String>("name", initial: "")
             let displayName = Value.Required<String>(
                 "displayName",
                 initial: "",
                 isTransient: true,
                 customGetter: Person.getName(_:)
             )
         
             private static func getName(_ partialObject: PartialObject<Person>) -> String {
                 let cachedDisplayName = partialObject.primitiveValue(for: { $0.displayName })
                 if !cachedDisplayName.isEmpty {
                     return cachedDisplayName
                 }
                 let title = partialObject.value(for: { $0.title })
                 let name = partialObject.value(for: { $0.name })
                 let displayName = "\(title) \(name)"
                 partialObject.setPrimitiveValue(displayName, for: { $0.displayName })
                 return displayName
             }
         }
         ```
         - parameter keyPath: the permanent attribute name for this property.
         - parameter initial: the initial value for the property when the object is first created
         - parameter isTransient: `true` if the property is transient, otherwise `false`. Defaults to `false` if not specified. The transient flag specifies whether or not a property's value is ignored when an object is saved to a persistent store. Transient properties are not saved to the persistent store, but are still managed for undo, redo, validation, and so on.
         - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
         - parameter renamingIdentifier: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property and a destination entity property that share the same identifier indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's name.
         - parameter customGetter: use this closure as an "override" for the default property getter. The closure receives a `PartialObject<O>`, which acts as a fast, type-safe KVC interface for `CoreStoreObject`. The reason a `CoreStoreObject` instance is not passed directly is because the Core Data runtime is not aware of `CoreStoreObject` properties' static typing, and so loading those info everytime KVO invokes this accessor method incurs a cumulative performance hit (especially in KVO-heavy operations such as `ListMonitor` observing.) When accessing the property value from `PartialObject<O>`, make sure to use `PartialObject<O>.primitiveValue(for:)` instead of `PartialObject<O>.value(for:)`, which would unintentionally execute the same closure again recursively.
         - parameter customSetter: use this closure as an "override" for the default property setter. The closure receives a `PartialObject<O>`, which acts as a fast, type-safe KVC interface for `CoreStoreObject`. The reason a `CoreStoreObject` instance is not passed directly is because the Core Data runtime is not aware of `CoreStoreObject` properties' static typing, and so loading those info everytime KVO invokes this accessor method incurs a cumulative performance hit (especially in KVO-heavy operations such as `ListMonitor` observing.) When accessing the property value from `PartialObject<O>`, make sure to use `PartialObject<O>.setPrimitiveValue(_:for:)` instead of `PartialObject<O>.setValue(_:for:)`, which would unintentionally execute the same closure again recursively.
         - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
         */
        public convenience init(
            _ keyPath: KeyPathString,
            initial: @autoclosure @escaping () -> V,
            isTransient: Bool = false,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            customGetter: ((_ partialObject: PartialObject<O>) -> V)? = nil,
            customSetter: ((_ partialObject: PartialObject<O>, _ newValue: V) -> Void)? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {

            self.init(
                wrappedValue: initial(),
                keyPath,
                isTransient: isTransient,
                versionHashModifier: versionHashModifier(),
                renamingIdentifier: renamingIdentifier(),
                customGetter: customGetter,
                customSetter: customSetter,
                affectedByKeyPaths: affectedByKeyPaths()
            )
        }

        public init(
            wrappedValue initialValue: @autoclosure @escaping () -> V,
            _ keyPath: KeyPathString,
            isTransient: Bool = false,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            customGetter: ((_ partialObject: PartialObject<O>) -> V)? = nil,
            customSetter: ((_ partialObject: PartialObject<O>, _ newValue: V) -> Void)? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {

            self.keyPath = keyPath
            self.isTransient = isTransient
            self.defaultValue = { initialValue().cs_toQueryableNativeType() }
            self.versionHashModifier = versionHashModifier
            self.renamingIdentifier = renamingIdentifier
            self.customGetter = customGetter
            self.customSetter = customSetter
            self.affectedByKeyPaths = affectedByKeyPaths
        }

        @available(*, unavailable)
        public var wrappedValue: V {

            get { fatalError() }
            set { fatalError() }
        }

//        @available(*, unavailable)
        public var projectedValue: ValueContainer<O>.Required<V> {

            get { return self }
            set {}
        }

        public static subscript(
            _enclosingInstance instance: O,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<O, V>,
            storage storageKeyPath: ReferenceWritableKeyPath<O, ValueContainer<O>.Required<V>>
        ) -> ReturnValueType {
            get {

                Internals.assert(
                    instance.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(instance.rawObject!) { (object) in

                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    let property = instance[keyPath: storageKeyPath]
                    if let customGetter = property.customGetter {

                        return customGetter(PartialObject<O>(object))
                    }
                    return V.cs_fromQueryableNativeType(
                        object.value(forKey: property.keyPath)! as! V.QueryableNativeType
                    )!
                }
            }
            set {

                Internals.assert(
                    instance.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(instance.rawObject!) { (object) in

                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    Internals.assert(
                        object.isEditableInContext() == true,
                        "Attempted to update a \(Internals.typeName(O.self))'s value from outside a transaction."
                    )
                    let property = instance[keyPath: storageKeyPath]
                    if let customSetter = property.customSetter {

                        return customSetter(PartialObject<O>(object), newValue)
                    }
                    return object.setValue(
                        newValue.cs_toQueryableNativeType(),
                        forKey: property.keyPath
                    )
                }
            }
        }

        /**
         The attribute value
         */
        public var value: ReturnValueType {
            
            get {
                
                Internals.assert(
                    self.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(self.rawObject!) { (object) in
                    
                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    if let customGetter = self.customGetter {
                        
                        return customGetter(PartialObject<O>(object))
                    }
                    return V.cs_fromQueryableNativeType(
                        object.value(forKey: self.keyPath)! as! V.QueryableNativeType
                    )!
                }
            }
            set {
                
                Internals.assert(
                    self.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(self.rawObject!) { (object) in
                    
                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    Internals.assert(
                        object.isEditableInContext() == true,
                        "Attempted to update a \(Internals.typeName(O.self))'s value from outside a transaction."
                    )
                    if let customSetter = self.customSetter {
                        
                        return customSetter(PartialObject<O>(object), newValue)
                    }
                    return object.setValue(
                        newValue.cs_toQueryableNativeType(),
                        forKey: self.keyPath
                    )
                }
            }
        }


        // MARK: AnyKeyPathStringConvertible

        public var cs_keyPathString: String {

            return self.keyPath
        }


        // MARK: KeyPathStringConvertible

        public typealias ObjectType = O
        public typealias DestinationValueType = V


        // MARK: AttributeKeyPathStringConvertible

        public typealias ReturnValueType = DestinationValueType
        
        
        // MARK: AttributeProtocol
        
        internal static var attributeType: NSAttributeType {
            
            return V.cs_rawAttributeType
        }
        
        internal let keyPath: KeyPathString
        internal let isOptional = false
        internal let isTransient: Bool
        internal let allowsExternalBinaryDataStorage = false
        internal let versionHashModifier: () -> String?
        internal let renamingIdentifier: () -> String?
        internal let defaultValue: () -> Any?
        internal let affectedByKeyPaths: () -> Set<String>
        internal var rawObject: CoreStoreManagedObject?
        
        internal private(set) lazy var getter: CoreStoreManagedObject.CustomGetter? = Internals.with { [unowned self] in
            
            guard let customGetter = self.customGetter else {
                
                return nil
            }
            let keyPath = self.keyPath
            return { (_ id: Any) -> Any? in
                
                let rawObject = id as! CoreStoreManagedObject
                rawObject.willAccessValue(forKey: keyPath)
                defer {
                    
                    rawObject.didAccessValue(forKey: keyPath)
                }
                let value = customGetter(PartialObject<O>(rawObject))
                return value.cs_toQueryableNativeType()
            }
        }
        
        internal private(set) lazy var setter: CoreStoreManagedObject.CustomSetter? = Internals.with { [unowned self] in
            
            guard let customSetter = self.customSetter else {
                
                return nil
            }
            let keyPath = self.keyPath
            return { (_ id: Any, _ newValue: Any?) -> Void in
                
                let rawObject = id as! CoreStoreManagedObject
                rawObject.willChangeValue(forKey: keyPath)
                defer {
                    
                    rawObject.didChangeValue(forKey: keyPath)
                }
                customSetter(
                    PartialObject<O>(rawObject),
                    V.cs_fromQueryableNativeType(newValue as! V.QueryableNativeType)!
                )
            }
        }
        
        internal var valueForSnapshot: Any {
            return self.value
        }
        
        
        // MARK: Private
        
        private let customGetter: ((_ partialObject: PartialObject<O>) -> V)?
        private let customSetter: ((_ partialObject: PartialObject<O>, _ newValue: V) -> Void)?
    }
    
    
    // MARK: - Optional
    
    /**
     The containing type for optional value properties. Any type that conforms to `ImportableAttributeType` are supported.
     ```
     class Animal: CoreStoreObject {
         let species = Value.Required<String>("species", initial: "")
         let nickname = Value.Optional<String>("nickname")
         let color = Transformable.Optional<UIColor>("color")
     }
     ```
     - Important: `Value.Optional` properties are required to be stored properties. Computed properties will be ignored, including `lazy` and `weak` properties.
     */
    public final class Optional<V: ImportableAttributeType>: AttributeKeyPathStringConvertible, AttributeProtocol {
        
        /**
         Initializes the metadata for the property.
         ```
         class Person: CoreStoreObject {
             let title = Value.Optional<String>("title", initial: "Mr.")
             let name = Value.Optional<String>("name")
             let displayName = Value.Optional<String>(
                 "displayName",
                 isTransient: true,
                 customGetter: Person.getName(_:)
             )
             
             private static func getName(_ partialObject: PartialObject<Person>) -> String? {
                 if let cachedDisplayName = partialObject.primitiveValue(for: { $0.displayName }) {
                    return cachedDisplayName
                 }
                 let title = partialObject.value(for: { $0.title })
                 let name = partialObject.value(for: { $0.name })
                 let displayName = "\(title) \(name)"
                 partialObject.setPrimitiveValue(displayName, for: { $0.displayName })
                 return displayName
             }
         }
         ```
         - parameter keyPath: the permanent attribute name for this property.
         - parameter initial: the initial value for the property when the object is first created. Defaults to `nil` if not specified.
         - parameter isTransient: `true` if the property is transient, otherwise `false`. Defaults to `false` if not specified. The transient flag specifies whether or not a property's value is ignored when an object is saved to a persistent store. Transient properties are not saved to the persistent store, but are still managed for undo, redo, validation, and so on.
         - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
         - parameter renamingIdentifier: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property and a destination entity property that share the same identifier indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's name.
         - parameter customGetter: use this closure to make final transformations to the property's value before returning from the getter.
         - parameter self: the `CoreStoreObject`
         - parameter getValue: the original getter for the property
         - parameter customSetter: use this closure to make final transformations to the new value before assigning to the property.
         - parameter setValue: the original setter for the property
         - parameter finalNewValue: the transformed new value
         - parameter originalNewValue: the original new value
         - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
         */
        public init(
            _ keyPath: KeyPathString,
            initial: @autoclosure @escaping () -> V? = nil,
            isTransient: Bool = false,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            customGetter: ((_ partialObject: PartialObject<O>) -> V?)? = nil,
            customSetter: ((_ partialObject: PartialObject<O>, _ newValue: V?) -> Void)? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {
            
            self.keyPath = keyPath
            self.isTransient = isTransient
            self.defaultValue = { initial()?.cs_toQueryableNativeType() }
            self.versionHashModifier = versionHashModifier
            self.renamingIdentifier = renamingIdentifier
            self.customGetter = customGetter
            self.customSetter = customSetter
            self.affectedByKeyPaths = affectedByKeyPaths
        }

        /**
         The attribute value
         */
        public var value: ReturnValueType {
            
            get {
                
                Internals.assert(
                    self.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(self.rawObject!) { (object) in
                    
                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    if let customGetter = self.customGetter {
                        
                        return customGetter(PartialObject<O>(object))
                    }
                    return (object.value(forKey: self.keyPath) as! V.QueryableNativeType?)
                        .flatMap(V.cs_fromQueryableNativeType)
                }
            }
            set {
                
                Internals.assert(
                    self.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(self.rawObject!) { (object) in
                    
                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    Internals.assert(
                        object.isEditableInContext() == true,
                        "Attempted to update a \(Internals.typeName(O.self))'s value from outside a transaction."
                    )
                    if let customSetter = self.customSetter {
                        
                        return customSetter(PartialObject<O>(object), newValue)
                    }
                    object.setValue(
                        newValue?.cs_toQueryableNativeType(),
                        forKey: self.keyPath
                    )
                }
            }
        }


        // MARK: AnyKeyPathStringConvertible

        public var cs_keyPathString: String {

            return self.keyPath
        }


        // MARK: KeyPathStringConvertible

        public typealias ObjectType = O
        public typealias DestinationValueType = V


        // MARK: AttributeKeyPathStringConvertible

        public typealias ReturnValueType = DestinationValueType?
        
        
        // MARK: AttributeProtocol
        
        internal static var attributeType: NSAttributeType {
            
            return V.cs_rawAttributeType
        }
        
        internal let keyPath: KeyPathString
        internal let isOptional = true
        internal let isTransient: Bool
        internal let allowsExternalBinaryDataStorage = false
        internal let versionHashModifier: () -> String?
        internal let renamingIdentifier: () -> String?
        internal let defaultValue: () -> Any?
        internal let affectedByKeyPaths: () -> Set<String>
        internal var rawObject: CoreStoreManagedObject?
        
        internal private(set) lazy var getter: CoreStoreManagedObject.CustomGetter? = Internals.with { [unowned self] in
            
            guard let customGetter = self.customGetter else {
                
                return nil
            }
            let keyPath = self.keyPath
            return { (_ id: Any) -> Any? in
                
                let rawObject = id as! CoreStoreManagedObject
                rawObject.willAccessValue(forKey: keyPath)
                defer {
                    
                    rawObject.didAccessValue(forKey: keyPath)
                }
                let value = customGetter(PartialObject<O>(rawObject))
                return value?.cs_toQueryableNativeType()
            }
        }
        
        internal private(set) lazy var setter: CoreStoreManagedObject.CustomSetter? = Internals.with { [unowned self] in
            
            guard let customSetter = self.customSetter else {
                
                return nil
            }
            let keyPath = self.keyPath
            return { (_ id: Any, _ newValue: Any?) -> Void in
                
                let rawObject = id as! CoreStoreManagedObject
                rawObject.willChangeValue(forKey: keyPath)
                defer {
                    
                    rawObject.didChangeValue(forKey: keyPath)
                }
                customSetter(
                    PartialObject<O>(rawObject),
                    (newValue as! V.QueryableNativeType?).flatMap(V.cs_fromQueryableNativeType)
                )
            }
        }
        
        internal var valueForSnapshot: Any {
            return self.value as Any
        }
        
        
        // MARK: Private
        
        private let customGetter: ((_ partialObject: PartialObject<O>) -> V?)?
        private let customSetter: ((_ partialObject: PartialObject<O>, _ newValue: V?) -> Void)?
    }
}


// MARK: - Operations

infix operator .= : AssignmentPrecedence
infix operator .== : ComparisonPrecedence

extension ValueContainer.Required {
    
    /**
     Assigns a value to the property. The operation
     ```
     animal.species .= "Swift"
     ```
     is equivalent to
     ```
     animal.species.value = "Swift"
     ```
     */
    public static func .= (_ property: ValueContainer<O>.Required<V>, _ newValue: V) {
        
        property.value = newValue
    }
    
    /**
     Assigns a value from another property. The operation
     ```
     animal.species .= anotherAnimal.species
     ```
     is equivalent to
     ```
     animal.species.value = anotherAnimal.species.value
     ```
     */
    public static func .= <O2>(_ property: ValueContainer<O>.Required<V>, _ property2: ValueContainer<O2>.Required<V>) {
        
        property.value = property2.value
    }
    
    /**
     Compares equality between a property's value and another value
     ```
     if animal.species .== "Swift" { ... }
     ```
     is equivalent to
     ```
     if animal.species.value == "Swift" { ... }
     ```
     */
    public static func .== (_ property: ValueContainer<O>.Required<V>, _ value: V?) -> Bool {
        
        return property.value == value
    }
    
    /**
     Compares equality between a value and a property's value
     ```
     if "Swift" .== animal.species { ... }
     ```
     is equivalent to
     ```
     if "Swift" == animal.species.value { ... }
     ```
     */
    public static func .== (_ value: V?, _ property: ValueContainer<O>.Required<V>) -> Bool {
        
        return value == property.value
    }
    
    /**
     Compares equality between a property's value and another property's value
     ```
     if animal.species .== anotherAnimal.species { ... }
     ```
     is equivalent to
     ```
     if animal.species.value == anotherAnimal.species.value { ... }
     ```
     */
    public static func .== (_ property: ValueContainer<O>.Required<V>, _ property2: ValueContainer<O>.Required<V>) -> Bool {
        
        return property.value == property2.value
    }
    
    /**
     Compares equality between a property's value and another property's value
     ```
     if animal.species .== anotherAnimal.species { ... }
     ```
     is equivalent to
     ```
     if animal.species.value == anotherAnimal.species.value { ... }
     ```
     */
    public static func .== (_ property: ValueContainer<O>.Required<V>, _ property2: ValueContainer<O>.Optional<V>) -> Bool {
        
        return property.value == property2.value
    }
}

extension ValueContainer.Optional {
    
    /**
     Assigns an optional value to the property. The operation
     ```
     animal.nickname .= "Taylor"
     ```
     is equivalent to
     ```
     animal.nickname.value = "Taylor"
     ```
     */
    public static func .= (_ property: ValueContainer<O>.Optional<V>, _ newValue: V?) {
        
        property.value = newValue
    }
    
    /**
     Assigns an optional value from another property. The operation
     ```
     animal.nickname .= anotherAnimal.nickname
     ```
     is equivalent to
     ```
     animal.nickname.value = anotherAnimal.nickname.value
     ```
     */
    public static func .= <O2>(_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O2>.Optional<V>) {
        
        property.value = property2.value
    }
    
    /**
     Assigns a value from another property. The operation
     ```
     animal.nickname .= anotherAnimal.species
     ```
     is equivalent to
     ```
     animal.nickname.value = anotherAnimal.species.value
     ```
     */
    public static func .= <O2>(_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O2>.Required<V>) {
        
        property.value = property2.value
    }
    
    /**
     Compares equality between a property's value and another value
     ```
     if animal.species .== "Swift" { ... }
     ```
     is equivalent to
     ```
     if animal.species.value == "Swift" { ... }
     ```
     */
    public static func .== (_ property: ValueContainer<O>.Optional<V>, _ value: V?) -> Bool {
        
        return property.value == value
    }
    
    /**
     Compares equality between a property's value and another property's value
     ```
     if "Swift" .== animal.species { ... }
     ```
     is equivalent to
     ```
     if "Swift" == animal.species.value { ... }
     ```
     */
    public static func .== (_ value: V?, _ property: ValueContainer<O>.Optional<V>) -> Bool {
        
        return value == property.value
    }
    
    /**
     Compares equality between a property's value and another property's value
     ```
     if animal.species .== anotherAnimal.species { ... }
     ```
     is equivalent to
     ```
     if animal.species.value == anotherAnimal.species.value { ... }
     ```
     */
    public static func .== (_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O>.Optional<V>) -> Bool {
        
        return property.value == property2.value
    }
    
    /**
     Compares equality between a property's value and another property's value
     ```
     if animal.species .== anotherAnimal.species { ... }
     ```
     is equivalent to
     ```
     if animal.species.value == anotherAnimal.species.value { ... }
     ```
     */
    public static func .== (_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O>.Required<V>) -> Bool {
        
        return property.value == property2.value
    }
}
