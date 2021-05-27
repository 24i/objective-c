// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PubNub",
    products: [
        .library(
            name: "PubNub",
            targets: [
                "PubNub"
            ]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "PubNub",
            dependencies: [],
            path: "PubNub",
            publicHeadersPath: "PubNub",
            cSettings: [
                //I could not find how to set the recursive option -_-
                .headerSearchPath("."),
                .headerSearchPath("Core"),
                .headerSearchPath("Data"),
                .headerSearchPath("Data/Builders"),
                .headerSearchPath("Data/Builders/API Call/Actions"),
                .headerSearchPath("Data/Builders/API Call/Actions/Message"),
                .headerSearchPath("Data/Builders/API Call/APNS"),
                .headerSearchPath("Data/Builders/API Call/Files"),
                .headerSearchPath("Data/Builders/API Call/History"),
                .headerSearchPath("Data/Builders/API Call/Objects"),
                .headerSearchPath("Data/Builders/API Call/Objects/Channel"),
                .headerSearchPath("Data/Builders/API Call/Objects/Membership"),
                .headerSearchPath("Data/Builders/API Call/Objects/UUID"),
                .headerSearchPath("Data/Builders/API Call/Presence"),
                .headerSearchPath("Data/Builders/API Call/Publish"),
                .headerSearchPath("Data/Builders/API Call/State"),
                .headerSearchPath("Data/Builders/API Call/Stream"),
                .headerSearchPath("Data/Builders/API Call/Subscribe"),
                .headerSearchPath("Data/Builders/API Call/Time"),
                .headerSearchPath("Data/Managers"),
                .headerSearchPath("Data/Models"),
                .headerSearchPath("Data/Service Objects"),
                .headerSearchPath("Data/Storage"),
                .headerSearchPath("Misc"),
                .headerSearchPath("Misc/Categories"),
                .headerSearchPath("Misc/Helpers"),
                .headerSearchPath("Misc/Helpers/Notifications Payload"),
                .headerSearchPath("Misc/Helpers/Notifications Payload/APNS"),
                .headerSearchPath("Misc/Logger"),
                .headerSearchPath("Misc/Logger/Core"),
                .headerSearchPath("Misc/Logger/Data"),
                .headerSearchPath("Misc/Protocols"),
                .headerSearchPath("Network"),
                .headerSearchPath("Network/Parsers"),
                .headerSearchPath("Network/Parsers/Actions"),
                .headerSearchPath("Network/Parsers/Files"),
                .headerSearchPath("Network/Parsers/Objects"),
                .headerSearchPath("Network/Requests"),
                .headerSearchPath("Network/Requests/Actions"),
                .headerSearchPath("Network/Requests/Actions/Message"),
                .headerSearchPath("Network/Requests/Files"),
                .headerSearchPath("Network/Requests/Objects"),
                .headerSearchPath("Network/Requests/Objects/Channel"),
                .headerSearchPath("Network/Requests/Objects/Membership"),
                .headerSearchPath("Network/Requests/Objects/UUID"),
                .headerSearchPath("Network/Requests/Publish"),
                .headerSearchPath("Network/Requests/Push Notifications"),
                .headerSearchPath("Network/Streams"),
            ]
        )
    ]
)
