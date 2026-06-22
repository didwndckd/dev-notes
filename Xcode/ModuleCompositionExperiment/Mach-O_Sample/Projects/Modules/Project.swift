@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Modules",
    targets: Targets.allCases.map { $0.moduleTarget }// + Targets.allCases.map { $0.appTarget }
)
