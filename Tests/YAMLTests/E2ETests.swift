import Testing
@testable import YAML

// MARK: - Helpers

private func expectScalar(_ node: Node?, equals expected: String, sourceLocation: SourceLocation = #_sourceLocation) {
    guard case .scalar(let s) = node else {
        Issue.record("Expected scalar, got \(String(describing: node))", sourceLocation: sourceLocation)
        return
    }
    #expect(s.string == expected, sourceLocation: sourceLocation)
}

private func requireMapping(_ node: Node?, sourceLocation: SourceLocation = #_sourceLocation) throws -> Node.Mapping {
    guard case .mapping(let m) = node else {
        Issue.record("Expected mapping, got \(String(describing: node))", sourceLocation: sourceLocation)
        throw TestFailure.wrongKind
    }
    return m
}

private func requireSequence(_ node: Node?, sourceLocation: SourceLocation = #_sourceLocation) throws -> Node.Sequence {
    guard case .sequence(let s) = node else {
        Issue.record("Expected sequence, got \(String(describing: node))", sourceLocation: sourceLocation)
        throw TestFailure.wrongKind
    }
    return s
}

private enum TestFailure: Error { case wrongKind }

// MARK: - E2E Suite

@Suite("E2E Tests - Real-world YAML documents", .tags(.e2e))
struct E2ETests {

    // MARK: GitHub Actions

    @Test("GitHub Actions workflow")
    func githubActionsWorkflow() throws {
        let yaml = """
        name: CI
        on:
          push:
            branches: [main, develop]
          pull_request:
            branches: [main]
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              matrix:
                swift: ["5.9", "5.10", "6.0"]
                os: [ubuntu-latest, macos-14]
            steps:
              - uses: actions/checkout@v4
              - name: Setup Swift
                uses: swift-actions/setup-swift@v2
                with:
                  swift-version: ${{ matrix.swift }}
              - name: Build
                run: swift build
              - name: Test
                run: swift test --parallel
        """

        let root = try requireMapping(try compose(yaml: yaml))
        expectScalar(root["name"], equals: "CI")

        let on = try requireMapping(root["on"])
        let push = try requireMapping(on["push"])
        let branches = try requireSequence(push["branches"])
        #expect(branches.count == 2)
        expectScalar(branches[0], equals: "main")
        expectScalar(branches[1], equals: "develop")

        let jobs = try requireMapping(root["jobs"])
        let test = try requireMapping(jobs["test"])
        expectScalar(test["runs-on"], equals: "ubuntu-latest")

        let strategy = try requireMapping(test["strategy"])
        let matrix = try requireMapping(strategy["matrix"])
        let swiftVersions = try requireSequence(matrix["swift"])
        #expect(swiftVersions.count == 3)
        expectScalar(swiftVersions[0], equals: "5.9")
        expectScalar(swiftVersions[2], equals: "6.0")

        let steps = try requireSequence(test["steps"])
        #expect(steps.count == 4)

        let checkout = try requireMapping(steps[0])
        expectScalar(checkout["uses"], equals: "actions/checkout@v4")

        let setupSwift = try requireMapping(steps[1])
        expectScalar(setupSwift["name"], equals: "Setup Swift")
        let setupWith = try requireMapping(setupSwift["with"])
        expectScalar(setupWith["swift-version"], equals: "${{ matrix.swift }}")

        let testStep = try requireMapping(steps[3])
        expectScalar(testStep["run"], equals: "swift test --parallel")
    }

    // MARK: Docker Compose

    @Test("Docker Compose service definitions")
    func dockerCompose() throws {
        let yaml = """
        version: "3.8"
        services:
          web:
            image: nginx:1.25-alpine
            ports:
              - "80:80"
              - "443:443"
            environment:
              - NGINX_HOST=example.com
              - NGINX_PORT=80
            volumes:
              - ./html:/usr/share/nginx/html:ro
            depends_on:
              - api
            restart: unless-stopped
          api:
            build:
              context: ./api
              dockerfile: Dockerfile
              args:
                NODE_ENV: production
            environment:
              DATABASE_URL: postgres://user:pass@db:5432/app
              LOG_LEVEL: info
            healthcheck:
              test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
              interval: 30s
              timeout: 10s
              retries: 3
          db:
            image: postgres:16
            volumes:
              - pgdata:/var/lib/postgresql/data
        volumes:
          pgdata:
        """

        let root = try requireMapping(try compose(yaml: yaml))
        expectScalar(root["version"], equals: "3.8")

        let services = try requireMapping(root["services"])

        let web = try requireMapping(services["web"])
        expectScalar(web["image"], equals: "nginx:1.25-alpine")
        expectScalar(web["restart"], equals: "unless-stopped")

        let ports = try requireSequence(web["ports"])
        #expect(ports.count == 2)
        expectScalar(ports[0], equals: "80:80")
        expectScalar(ports[1], equals: "443:443")

        let env = try requireSequence(web["environment"])
        #expect(env.count == 2)
        expectScalar(env[0], equals: "NGINX_HOST=example.com")

        let api = try requireMapping(services["api"])
        let build = try requireMapping(api["build"])
        expectScalar(build["context"], equals: "./api")
        let buildArgs = try requireMapping(build["args"])
        expectScalar(buildArgs["NODE_ENV"], equals: "production")

        let apiEnv = try requireMapping(api["environment"])
        expectScalar(apiEnv["DATABASE_URL"], equals: "postgres://user:pass@db:5432/app")

        let healthcheck = try requireMapping(api["healthcheck"])
        let healthTest = try requireSequence(healthcheck["test"])
        #expect(healthTest.count == 4)
        expectScalar(healthTest[0], equals: "CMD")
        expectScalar(healthTest[3], equals: "http://localhost:3000/health")
        expectScalar(healthcheck["retries"], equals: "3")

        let volumes = try requireMapping(root["volumes"])
        #expect(volumes.count == 1)
    }

    // MARK: Kubernetes (multi-document)

    @Test("Kubernetes multi-document manifest")
    func kubernetesMultiDocument() throws {
        let yaml = """
        ---
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: app-config
          namespace: production
        data:
          DATABASE_HOST: db.internal
          LOG_LEVEL: info
        ---
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: web
          labels:
            app: web
            tier: frontend
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: web
          template:
            metadata:
              labels:
                app: web
            spec:
              containers:
                - name: web
                  image: nginx:1.25
                  ports:
                    - containerPort: 80
                  resources:
                    requests:
                      cpu: 100m
                      memory: 128Mi
                    limits:
                      cpu: 500m
                      memory: 512Mi
        """

        let docs = try composeAll(yaml: yaml)
        #expect(docs.count == 2)

        // Document 1: ConfigMap
        let cm = try requireMapping(docs[0])
        expectScalar(cm["apiVersion"], equals: "v1")
        expectScalar(cm["kind"], equals: "ConfigMap")
        let cmMeta = try requireMapping(cm["metadata"])
        expectScalar(cmMeta["namespace"], equals: "production")
        let cmData = try requireMapping(cm["data"])
        expectScalar(cmData["DATABASE_HOST"], equals: "db.internal")

        // Document 2: Deployment
        let dep = try requireMapping(docs[1])
        expectScalar(dep["kind"], equals: "Deployment")
        let depSpec = try requireMapping(dep["spec"])
        expectScalar(depSpec["replicas"], equals: "3")

        let template = try requireMapping(depSpec["template"])
        let templateSpec = try requireMapping(template["spec"])
        let containers = try requireSequence(templateSpec["containers"])
        #expect(containers.count == 1)

        let container = try requireMapping(containers[0])
        expectScalar(container["name"], equals: "web")
        expectScalar(container["image"], equals: "nginx:1.25")

        let resources = try requireMapping(container["resources"])
        let limits = try requireMapping(resources["limits"])
        expectScalar(limits["cpu"], equals: "500m")
        expectScalar(limits["memory"], equals: "512Mi")
    }

    // MARK: Rails database.yml (anchors + aliases)

    @Test("Rails database.yml with anchors and aliases")
    func railsDatabaseYaml() throws {
        let yaml = """
        default: &default
          adapter: postgresql
          encoding: unicode
          pool: 5
          timeout: 5000

        development:
          <<: *default
          database: myapp_development

        test:
          <<: *default
          database: myapp_test

        production:
          <<: *default
          database: myapp_production
          username: myapp
          password: <%= ENV['DATABASE_PASSWORD'] %>
        """

        let root = try requireMapping(try compose(yaml: yaml))

        // Anchor resolution: *default expands to the mapping under `default`
        let dev = try requireMapping(root["development"])
        // The merge key `<<` is preserved as a key (this parser does not implement
        // merge-key semantics; it only resolves the alias to the anchor target).
        expectScalar(dev["database"], equals: "myapp_development")

        let prod = try requireMapping(root["production"])
        expectScalar(prod["database"], equals: "myapp_production")
        expectScalar(prod["username"], equals: "myapp")
        expectScalar(prod["password"], equals: "<%= ENV['DATABASE_PASSWORD'] %>")

        // The alias target itself is reachable from <<
        let merge = dev["<<"]
        let defaultMap = try requireMapping(merge)
        expectScalar(defaultMap["adapter"], equals: "postgresql")
        expectScalar(defaultMap["pool"], equals: "5")
    }

    // MARK: OpenAPI / Swagger spec

    @Test("OpenAPI 3.0 spec fragment")
    func openAPISpec() throws {
        let yaml = """
        openapi: 3.0.3
        info:
          title: Pet Store API
          version: 1.0.0
          description: |
            A sample API that uses a petstore as an example to demonstrate
            features in the OpenAPI 3.0 specification.
        servers:
          - url: https://api.example.com/v1
            description: Production
          - url: https://staging.example.com/v1
            description: Staging
        paths:
          /pets:
            get:
              summary: List all pets
              operationId: listPets
              parameters:
                - name: limit
                  in: query
                  required: false
                  schema:
                    type: integer
                    format: int32
                    maximum: 100
              responses:
                '200':
                  description: A paged array of pets
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/Pets'
        components:
          schemas:
            Pet:
              type: object
              required:
                - id
                - name
              properties:
                id:
                  type: integer
                  format: int64
                name:
                  type: string
                tag:
                  type: string
        """

        let root = try requireMapping(try compose(yaml: yaml))
        expectScalar(root["openapi"], equals: "3.0.3")

        let info = try requireMapping(root["info"])
        expectScalar(info["title"], equals: "Pet Store API")
        expectScalar(info["version"], equals: "1.0.0")
        // Literal block scalar keeps a trailing newline (clip mode)
        guard case .scalar(let desc) = info["description"] else {
            Issue.record("Expected description scalar")
            return
        }
        #expect(desc.string.contains("petstore as an example"))
        #expect(desc.string.hasSuffix("\n"))

        let servers = try requireSequence(root["servers"])
        #expect(servers.count == 2)
        let prodServer = try requireMapping(servers[0])
        expectScalar(prodServer["url"], equals: "https://api.example.com/v1")

        let paths = try requireMapping(root["paths"])
        let pets = try requireMapping(paths["/pets"])
        let get = try requireMapping(pets["get"])
        expectScalar(get["operationId"], equals: "listPets")

        let params = try requireSequence(get["parameters"])
        let limit = try requireMapping(params[0])
        expectScalar(limit["name"], equals: "limit")
        let limitSchema = try requireMapping(limit["schema"])
        expectScalar(limitSchema["maximum"], equals: "100")

        // Numeric-looking string key '200' must be quoted in the source
        let responses = try requireMapping(get["responses"])
        let ok = try requireMapping(responses["200"])
        let content = try requireMapping(ok["content"])
        let appJson = try requireMapping(content["application/json"])
        let schema = try requireMapping(appJson["schema"])
        expectScalar(schema["$ref"], equals: "#/components/schemas/Pets")

        let components = try requireMapping(root["components"])
        let schemas = try requireMapping(components["schemas"])
        let pet = try requireMapping(schemas["Pet"])
        let required = try requireSequence(pet["required"])
        #expect(required.count == 2)
        expectScalar(required[0], equals: "id")
        expectScalar(required[1], equals: "name")
    }

    // MARK: Ansible playbook

    @Test("Ansible playbook with multiple tasks")
    func ansiblePlaybook() throws {
        let yaml = """
        - name: Configure web servers
          hosts: webservers
          become: true
          vars:
            http_port: 80
            max_clients: 200
          tasks:
            - name: Ensure nginx is installed
              apt:
                name: nginx
                state: present
                update_cache: true
            - name: Copy nginx config
              template:
                src: nginx.conf.j2
                dest: /etc/nginx/nginx.conf
                owner: root
                mode: '0644'
              notify:
                - Restart nginx
            - name: Ensure nginx is running
              service:
                name: nginx
                state: started
                enabled: true
          handlers:
            - name: Restart nginx
              service:
                name: nginx
                state: restarted
        """

        let plays = try requireSequence(try compose(yaml: yaml))
        #expect(plays.count == 1)

        let play = try requireMapping(plays[0])
        expectScalar(play["name"], equals: "Configure web servers")
        expectScalar(play["hosts"], equals: "webservers")
        expectScalar(play["become"], equals: "true")

        let vars = try requireMapping(play["vars"])
        expectScalar(vars["http_port"], equals: "80")
        expectScalar(vars["max_clients"], equals: "200")

        let tasks = try requireSequence(play["tasks"])
        #expect(tasks.count == 3)

        let installTask = try requireMapping(tasks[0])
        expectScalar(installTask["name"], equals: "Ensure nginx is installed")
        let apt = try requireMapping(installTask["apt"])
        expectScalar(apt["name"], equals: "nginx")
        expectScalar(apt["state"], equals: "present")

        let copyTask = try requireMapping(tasks[1])
        let template = try requireMapping(copyTask["template"])
        expectScalar(template["dest"], equals: "/etc/nginx/nginx.conf")
        expectScalar(template["mode"], equals: "0644")

        let notify = try requireSequence(copyTask["notify"])
        #expect(notify.count == 1)
        expectScalar(notify[0], equals: "Restart nginx")

        let handlers = try requireSequence(play["handlers"])
        #expect(handlers.count == 1)
        let restart = try requireMapping(handlers[0])
        expectScalar(restart["name"], equals: "Restart nginx")
    }

    // MARK: Helm values.yaml

    @Test("Helm values.yaml with nested configuration")
    func helmValues() throws {
        let yaml = """
        replicaCount: 2
        image:
          repository: nginx
          pullPolicy: IfNotPresent
          tag: "1.25.3"
        imagePullSecrets: []
        nameOverride: ""
        fullnameOverride: ""
        serviceAccount:
          create: true
          annotations: {}
          name: ""
        podAnnotations: {}
        podSecurityContext:
          fsGroup: 2000
        securityContext:
          capabilities:
            drop:
              - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        service:
          type: ClusterIP
          port: 80
        ingress:
          enabled: false
          className: ""
          annotations: {}
          hosts:
            - host: chart-example.local
              paths:
                - path: /
                  pathType: ImplementationSpecific
          tls: []
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 128Mi
        autoscaling:
          enabled: false
          minReplicas: 1
          maxReplicas: 100
          targetCPUUtilizationPercentage: 80
        nodeSelector: {}
        tolerations: []
        affinity: {}
        """

        let root = try requireMapping(try compose(yaml: yaml))
        expectScalar(root["replicaCount"], equals: "2")

        let image = try requireMapping(root["image"])
        expectScalar(image["repository"], equals: "nginx")
        expectScalar(image["tag"], equals: "1.25.3")

        let pullSecrets = try requireSequence(root["imagePullSecrets"])
        #expect(pullSecrets.isEmpty)

        let serviceAccount = try requireMapping(root["serviceAccount"])
        expectScalar(serviceAccount["create"], equals: "true")
        let saAnnotations = try requireMapping(serviceAccount["annotations"])
        #expect(saAnnotations.isEmpty)

        let security = try requireMapping(root["securityContext"])
        let caps = try requireMapping(security["capabilities"])
        let drop = try requireSequence(caps["drop"])
        #expect(drop.count == 1)
        expectScalar(drop[0], equals: "ALL")

        let ingress = try requireMapping(root["ingress"])
        let hosts = try requireSequence(ingress["hosts"])
        let firstHost = try requireMapping(hosts[0])
        expectScalar(firstHost["host"], equals: "chart-example.local")
        let paths = try requireSequence(firstHost["paths"])
        let firstPath = try requireMapping(paths[0])
        expectScalar(firstPath["path"], equals: "/")
        expectScalar(firstPath["pathType"], equals: "ImplementationSpecific")

        let autoscaling = try requireMapping(root["autoscaling"])
        expectScalar(autoscaling["maxReplicas"], equals: "100")
    }

    // MARK: GitLab CI with YAML anchors

    @Test("GitLab CI with reusable anchors")
    func gitlabCIAnchors() throws {
        let yaml = """
        stages:
          - build
          - test
          - deploy

        .swift_job: &swift_job
          image: swift:6.0
          before_script:
            - swift --version
          tags:
            - docker

        build:
          <<: *swift_job
          stage: build
          script:
            - swift build -c release
          artifacts:
            paths:
              - .build/release/

        unit-test:
          <<: *swift_job
          stage: test
          script:
            - swift test --parallel
          coverage: '/LINE COVERAGE: (\\d+\\.\\d+)/'
        """

        let root = try requireMapping(try compose(yaml: yaml))

        let stages = try requireSequence(root["stages"])
        #expect(stages.count == 3)
        expectScalar(stages[0], equals: "build")
        expectScalar(stages[2], equals: "deploy")

        let build = try requireMapping(root["build"])
        expectScalar(build["stage"], equals: "build")

        // Alias expansion: the <<: *swift_job entry resolves to the anchor target
        let merge = build["<<"]
        let swiftJob = try requireMapping(merge)
        expectScalar(swiftJob["image"], equals: "swift:6.0")

        let buildScript = try requireSequence(build["script"])
        expectScalar(buildScript[0], equals: "swift build -c release")

        let artifacts = try requireMapping(build["artifacts"])
        let paths = try requireSequence(artifacts["paths"])
        expectScalar(paths[0], equals: ".build/release/")

        let unitTest = try requireMapping(root["unit-test"])
        expectScalar(unitTest["coverage"], equals: "/LINE COVERAGE: (\\d+\\.\\d+)/")
    }

    // MARK: pubspec.yaml (Dart/Flutter)

    @Test("Dart pubspec.yaml")
    func dartPubspec() throws {
        let yaml = """
        name: my_app
        description: A sample Flutter application.
        publish_to: 'none'
        version: 1.0.0+1

        environment:
          sdk: '>=3.2.0 <4.0.0'
          flutter: ">=3.16.0"

        dependencies:
          flutter:
            sdk: flutter
          cupertino_icons: ^1.0.6
          http: ^1.1.0
          provider: ^6.1.1

        dev_dependencies:
          flutter_test:
            sdk: flutter
          flutter_lints: ^3.0.1

        flutter:
          uses-material-design: true
          assets:
            - assets/images/
            - assets/fonts/
          fonts:
            - family: Roboto
              fonts:
                - asset: assets/fonts/Roboto-Regular.ttf
                - asset: assets/fonts/Roboto-Bold.ttf
                  weight: 700
        """

        let root = try requireMapping(try compose(yaml: yaml))
        expectScalar(root["name"], equals: "my_app")
        expectScalar(root["version"], equals: "1.0.0+1")

        let env = try requireMapping(root["environment"])
        expectScalar(env["sdk"], equals: ">=3.2.0 <4.0.0")
        expectScalar(env["flutter"], equals: ">=3.16.0")

        let deps = try requireMapping(root["dependencies"])
        let flutterDep = try requireMapping(deps["flutter"])
        expectScalar(flutterDep["sdk"], equals: "flutter")
        expectScalar(deps["cupertino_icons"], equals: "^1.0.6")
        expectScalar(deps["http"], equals: "^1.1.0")

        let flutter = try requireMapping(root["flutter"])
        let assets = try requireSequence(flutter["assets"])
        #expect(assets.count == 2)
        expectScalar(assets[0], equals: "assets/images/")

        let fonts = try requireSequence(flutter["fonts"])
        let firstFamily = try requireMapping(fonts[0])
        expectScalar(firstFamily["family"], equals: "Roboto")
        let familyFonts = try requireSequence(firstFamily["fonts"])
        #expect(familyFonts.count == 2)
        let boldFont = try requireMapping(familyFonts[1])
        expectScalar(boldFont["asset"], equals: "assets/fonts/Roboto-Bold.ttf")
        expectScalar(boldFont["weight"], equals: "700")
    }

    // MARK: Multi-document stream ordering

    @Test("Stream of three documents preserves order")
    func multiDocumentStream() throws {
        let yaml = """
        ---
        id: 1
        name: first
        ---
        id: 2
        name: second
        ---
        id: 3
        name: third
        ...
        """

        let docs = try composeAll(yaml: yaml)
        #expect(docs.count == 3)

        for (i, doc) in docs.enumerated() {
            let m = try requireMapping(doc)
            expectScalar(m["id"], equals: "\(i + 1)")
        }

        expectScalar(try requireMapping(docs[0])["name"], equals: "first")
        expectScalar(try requireMapping(docs[1])["name"], equals: "second")
        expectScalar(try requireMapping(docs[2])["name"], equals: "third")
    }

    // MARK: Block scalar styles in a realistic config

    @Test("Config with literal and folded block scalars")
    func blockScalarConfig() throws {
        let yaml = """
        message:
          literal: |
            Line one
            Line two
            Line three
          folded: >
            This is a long
            paragraph that should
            be folded into one line.
          literal_strip: |-
            No trailing newline
          folded_keep: >+
            Keep trailing newlines


        """

        let root = try requireMapping(try compose(yaml: yaml))
        let message = try requireMapping(root["message"])

        guard case .scalar(let literal) = message["literal"] else {
            Issue.record("Expected literal scalar")
            return
        }
        #expect(literal.string == "Line one\nLine two\nLine three\n")

        guard case .scalar(let folded) = message["folded"] else {
            Issue.record("Expected folded scalar")
            return
        }
        #expect(folded.string == "This is a long paragraph that should be folded into one line.\n")

        guard case .scalar(let literalStrip) = message["literal_strip"] else {
            Issue.record("Expected literal_strip scalar")
            return
        }
        #expect(literalStrip.string == "No trailing newline")

        guard case .scalar(let foldedKeep) = message["folded_keep"] else {
            Issue.record("Expected folded_keep scalar")
            return
        }
        #expect(foldedKeep.string.hasPrefix("Keep trailing newlines"))
        // `>+` keeps all trailing newlines — more than the single newline of clip mode
        #expect(foldedKeep.string.hasSuffix("\n\n"))
    }
}
