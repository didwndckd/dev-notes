@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

let workspace = Workspace(
    name: Define.appName,
    projects: [
        .relativeToRoot("\(Define.projectPath)/\(Define.appName)"),
        .relativeToRoot(Define.modulePath),
    ],
    additionalFiles: []
)
