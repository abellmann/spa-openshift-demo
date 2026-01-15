#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-team2-demo-optimized}"

echo "Creating optimized demo project structure in: ${BASE_DIR}"

mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}"

# --- Backend ----------------------------------------------------
echo "Creating backend structure..."
mkdir -p backend/src/main/java/com/example/demo
mkdir -p backend/src/main/resources

cat > backend/pom.xml <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>team2-backend</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>team2-backend</name>
    <description>Team 2 Demo Backend</description>

    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <finalName>app</finalName>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

cat > backend/src/main/java/com/example/demo/DemoApplication.java <<'EOF'
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
EOF

cat > backend/src/main/java/com/example/demo/HelloController.java <<'EOF'
package com.example.demo;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@CrossOrigin(origins = "*") // In production, specify exact origins
public class HelloController {

    @GetMapping("/api/hello")
    public Message hello() {
        return new Message("Hello from Spring Boot Backend");
    }

    @GetMapping("/api/health")
    public Status health() {
        return new Status("UP");
    }

    public record Message(String message) {}
    public record Status(String status) {}
}
EOF

cat > backend/src/main/resources/application.yml <<'EOF'
server:
  port: 8080
  shutdown: graceful

spring:
  application:
    name: team2-backend
  lifecycle:
    timeout-per-shutdown-phase: 30s

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: when-authorized
EOF

cat > backend/.dockerignore <<'EOF'
target/
.mvn/
*.iml
.idea/
.settings/
.classpath
.project
EOF

# --- Frontend ---------------------------------------------------
echo "Creating frontend structure..."
mkdir -p frontend/src/app
mkdir -p frontend/src/environments

cat > frontend/package.json <<'EOF'
{
  "name": "team2-frontend",
  "version": "0.0.1",
  "scripts": {
    "ng": "ng",
    "start": "ng serve --proxy-config proxy.conf.json",
    "build": "ng build --configuration production",
    "build:dev": "ng build",
    "test": "ng test",
    "lint": "ng lint"
  },
  "private": true,
  "dependencies": {
    "@angular/animations": "15.2.10",
    "@angular/common": "15.2.10",
    "@angular/compiler": "15.2.10",
    "@angular/core": "15.2.10",
    "@angular/forms": "15.2.10",
    "@angular/platform-browser": "15.2.10",
    "@angular/platform-browser-dynamic": "15.2.10",
    "@angular/router": "15.2.10",
    "rxjs": "7.8.1",
    "tslib": "2.6.2",
    "zone.js": "0.11.8"
  },
  "devDependencies": {
    "@angular-devkit/build-angular": "15.2.10",
    "@angular/cli": "15.2.10",
    "@angular/compiler-cli": "15.2.10",
    "@types/node": "18.19.3",
    "typescript": "4.9.5"
  }
}
EOF

cat > frontend/proxy.conf.json <<'EOF'
{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false,
    "logLevel": "debug",
    "changeOrigin": true
  }
}
EOF

cat > frontend/angular.json <<'EOF'
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "newProjectRoot": "projects",
  "projects": {
    "team2-frontend": {
      "projectType": "application",
      "schematics": {},
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular-devkit/build-angular:browser",
          "options": {
            "outputPath": "dist/team2-frontend",
            "index": "src/index.html",
            "main": "src/main.ts",
            "polyfills": ["zone.js"],
            "tsConfig": "tsconfig.app.json",
            "assets": [
              "src/favicon.ico"
            ],
            "styles": [],
            "scripts": []
          },
          "configurations": {
            "production": {
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "500kb",
                  "maximumError": "1mb"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "2kb",
                  "maximumError": "4kb"
                }
              ],
              "outputHashing": "all",
              "optimization": true,
              "sourceMap": false,
              "namedChunks": false,
              "extractLicenses": true,
              "buildOptimizer": true
            },
            "development": {
              "buildOptimizer": false,
              "optimization": false,
              "vendorChunk": true,
              "extractLicenses": false,
              "sourceMap": true,
              "namedChunks": true
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular-devkit/build-angular:dev-server",
          "configurations": {
            "production": {
              "buildTarget": "team2-frontend:build:production"
            },
            "development": {
              "buildTarget": "team2-frontend:build:development"
            }
          },
          "defaultConfiguration": "development"
        }
      }
    }
  }
}
EOF

cat > frontend/tsconfig.app.json <<'EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./out-tsc/app",
    "types": []
  },
  "files": [
    "src/main.ts"
  ],
  "include": [
    "src/**/*.d.ts"
  ]
}
EOF

cat > frontend/tsconfig.json <<'EOF'
{
  "compileOnSave": false,
  "compilerOptions": {
    "baseUrl": "./",
    "outDir": "./dist/out-tsc",
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "sourceMap": true,
    "declaration": false,
    "downlevelIteration": true,
    "experimentalDecorators": true,
    "moduleResolution": "node",
    "importHelpers": true,
    "target": "ES2022",
    "module": "ES2022",
    "useDefineForClassFields": false,
    "lib": [
      "ES2022",
      "dom"
    ]
  },
  "angularCompilerOptions": {
    "enableI18nLegacyMessageIdFormat": false,
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true,
    "strictTemplates": true
  }
}
EOF

cat > frontend/src/environments/environment.ts <<'EOF'
export const environment = {
  production: false,
  apiUrl: '/api'
};
EOF

cat > frontend/src/environments/environment.prod.ts <<'EOF'
export const environment = {
  production: true,
  apiUrl: '/api'
};
EOF

cat > frontend/src/app/api.service.ts <<'EOF'
import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';
import { environment } from '../environments/environment';

export interface HelloResponse {
  message: string;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getHello(): Observable<HelloResponse> {
    return this.http.get<HelloResponse>(`${this.baseUrl}/hello`).pipe(
      retry(1),
      catchError(this.handleError)
    );
  }

  private handleError(error: HttpErrorResponse): Observable<never> {
    let errorMessage = 'An error occurred';
    if (error.error instanceof ErrorEvent) {
      errorMessage = `Client error: ${error.error.message}`;
    } else {
      errorMessage = `Server error: ${error.status} - ${error.message}`;
    }
    console.error(errorMessage);
    return throwError(() => new Error(errorMessage));
  }
}
EOF

cat > frontend/src/app/app.component.ts <<'EOF'
import { Component } from '@angular/core';
import { ApiService, HelloResponse } from './api.service';

@Component({
  selector: 'app-root',
  template: `
    <div class="container">
      <h1>Team 2 Demo Frontend</h1>
      <button (click)="callBackend()" [disabled]="loading">
        {{ loading ? 'Loading...' : 'Call Backend' }}
      </button>
      <div *ngIf="response" class="success">
        <strong>Backend says:</strong> {{ response.message }}
      </div>
      <div *ngIf="error" class="error">
        <strong>Error:</strong> {{ error }}
      </div>
    </div>
  `,
  styles: [`
    .container {
      max-width: 600px;
      margin: 50px auto;
      padding: 20px;
      font-family: Arial, sans-serif;
    }
    h1 {
      color: #333;
    }
    button {
      padding: 10px 20px;
      font-size: 16px;
      background-color: #007bff;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      margin: 20px 0;
    }
    button:hover:not(:disabled) {
      background-color: #0056b3;
    }
    button:disabled {
      background-color: #ccc;
      cursor: not-allowed;
    }
    .success {
      padding: 15px;
      background-color: #d4edda;
      border: 1px solid #c3e6cb;
      border-radius: 4px;
      color: #155724;
      margin-top: 20px;
    }
    .error {
      padding: 15px;
      background-color: #f8d7da;
      border: 1px solid #f5c6cb;
      border-radius: 4px;
      color: #721c24;
      margin-top: 20px;
    }
  `]
})
export class AppComponent {
  response?: HelloResponse;
  error?: string;
  loading = false;

  constructor(private api: ApiService) {}

  callBackend(): void {
    this.loading = true;
    this.error = undefined;
    this.response = undefined;

    this.api.getHello().subscribe({
      next: (res) => {
        this.response = res;
        this.loading = false;
      },
      error: (err) => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }
}
EOF

cat > frontend/src/app/app.module.ts <<'EOF'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { AppComponent } from './app.component';

@NgModule({
  declarations: [AppComponent],
  imports: [BrowserModule, HttpClientModule],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {}
EOF

cat > frontend/src/main.ts <<'EOF'
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

platformBrowserDynamic().bootstrapModule(AppModule)
  .catch(err => console.error(err));
EOF

cat > frontend/src/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Team 2 Demo Frontend</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
EOF

cat > frontend/src/favicon.ico <<'EOF'
EOF

cat > frontend/.dockerignore <<'EOF'
node_modules/
dist/
.angular/
*.log
.idea/
.vscode/
EOF

# --- Gateway (consolidated) -------------------------------------
echo "Creating consolidated gateway..."
mkdir -p gateway

cat > gateway/nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10m;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    server {
        listen 8080;
        server_name _;

        root /usr/share/nginx/html;
        index index.html;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Backend API proxy
        location /api/ {
            proxy_pass http://backend-team2:8080/api/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Frontend static files
        location / {
            try_files $uri $uri/ /index.html;
            
            # Cache static assets
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Custom error pages
        error_page 404 /index.html;
        error_page 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
            internal;
        }
    }
}
EOF

cat > gateway/50x.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Service Unavailable</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #d9534f; }
    </style>
</head>
<body>
    <h1>Service Temporarily Unavailable</h1>
    <p>Please try again in a few moments.</p>
</body>
</html>
EOF

# --- Docker -----------------------------------------------------
echo "Creating Docker configurations..."
mkdir -p docker

cat > docker/Dockerfile.backend <<'EOF'
# Multi-stage build for Spring Boot backend
FROM maven:3.9-eclipse-temurin-17-alpine AS build
WORKDIR /build

# Copy pom.xml and download dependencies (cached layer)
COPY backend/pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build
COPY backend/src ./src
RUN mvn clean package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy jar from build stage
COPY --from=build /build/target/app.jar app.jar

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

EXPOSE 8080
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", \
  "/app/app.jar"]
EOF

cat > docker/Dockerfile.gateway <<'EOF'
# Multi-stage build for gateway with frontend
FROM node:18-alpine AS frontend-build
WORKDIR /build

# Install dependencies (cached layer)
COPY frontend/package*.json ./
RUN npm ci --legacy-peer-deps

# Build frontend
COPY frontend/ .
RUN npm run build

# Gateway runtime with frontend static files
FROM nginx:1.25-alpine
WORKDIR /usr/share/nginx/html

# Copy frontend build
COPY --from=frontend-build /build/dist/team2-frontend/ .

# Copy nginx configuration
COPY gateway/nginx.conf /etc/nginx/nginx.conf
COPY gateway/50x.html .

# Create non-root user and adjust permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
EOF

# --- Docker Compose ---------------------------------------------
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: docker/Dockerfile.backend
    container_name: team2-backend
    environment:
      - SPRING_PROFILES_ACTIVE=docker
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
    networks:
      - team2-network

  gateway:
    build:
      context: .
      dockerfile: docker/Dockerfile.gateway
    container_name: team2-gateway
    ports:
      - "3000:8080"
    depends_on:
      backend:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    networks:
      - team2-network

networks:
  team2-network:
    driver: bridge
EOF

# --- OpenShift --------------------------------------------------
echo "Creating OpenShift manifests..."
mkdir -p openshift

cat > openshift/namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: team2-demo
  labels:
    name: team2-demo
EOF

cat > openshift/backend-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-team2
  namespace: team2-demo
  labels:
    app: backend-team2
    version: v1
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: backend-team2
  template:
    metadata:
      labels:
        app: backend-team2
        version: v1
    spec:
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: backend
          image: ${REGISTRY}/team2-backend:${VERSION}
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          env:
            - name: JAVA_OPTS
              value: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
            - name: SPRING_PROFILES_ACTIVE
              value: "openshift"
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: http
            initialDelaySeconds: 60
            periodSeconds: 20
            timeoutSeconds: 3
            failureThreshold: 3
          resources:
            requests:
              cpu: "200m"
              memory: "384Mi"
            limits:
              cpu: "1000m"
              memory: "768Mi"
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
---
apiVersion: v1
kind: Service
metadata:
  name: backend-team2
  namespace: team2-demo
  labels:
    app: backend-team2
spec:
  type: ClusterIP
  selector:
    app: backend-team2
  ports:
    - name: http
      port: 8080
      targetPort: http
      protocol: TCP
  sessionAffinity: None
EOF

cat > openshift/gateway-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway-team2
  namespace: team2-demo
  labels:
    app: gateway-team2
    version: v1
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: gateway-team2
  template:
    metadata:
      labels:
        app: gateway-team2
        version: v1
    spec:
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: gateway
          image: ${REGISTRY}/team2-gateway:${VERSION}
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 20
            timeoutSeconds: 3
            failureThreshold: 3
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "256Mi"
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
---
apiVersion: v1
kind: Service
metadata:
  name: gateway-team2
  namespace: team2-demo
  labels:
    app: gateway-team2
spec:
  type: ClusterIP
  selector:
    app: gateway-team2
  ports:
    - name: http
      port: 8080
      targetPort: http
      protocol: TCP
  sessionAffinity: None
EOF

cat > openshift/route.yaml <<'EOF'
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: team2-demo
  namespace: team2-demo
  labels:
    app: gateway-team2
spec:
  host: team2-demo.apps.your-cluster.com
  to:
    kind: Service
    name: gateway-team2
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
EOF

cat > openshift/network-policy.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: team2-network-policy
  namespace: team2-demo
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              network.openshift.io/policy-group: ingress
      ports:
        - protocol: TCP
          port: 8080
    - from:
        - podSelector:
            matchLabels:
              app: gateway-team2
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: backend-team2
      ports:
        - protocol: TCP
          port: 8080
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
EOF

cat > openshift/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: team2-demo

resources:
  - namespace.yaml
  - backend-deployment.yaml
  - gateway-deployment.yaml
  - route.yaml
  - network-policy.yaml

images:
  - name: ${REGISTRY}/team2-backend
    newTag: ${VERSION}
  - name: ${REGISTRY}/team2-gateway
    newTag: ${VERSION}

commonLabels:
  app.kubernetes.io/name: team2-demo
  app.kubernetes.io/part-of: team2-demo
EOF

# --- Build and deploy scripts -----------------------------------
cat > build.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-your-registry.io/team2}"
VERSION="${VERSION:-0.0.1}"

echo "Building images..."
echo "Registry: ${REGISTRY}"
echo "Version: ${VERSION}"

# Build backend
echo "Building backend..."
docker build -f docker/Dockerfile.backend \
  -t "${REGISTRY}/team2-backend:${VERSION}" \
  -t "${REGISTRY}/team2-backend:latest" \
  .

# Build gateway (includes frontend)
echo "Building gateway with frontend..."
docker build -f docker/Dockerfile.gateway \
  -t "${REGISTRY}/team2-gateway:${VERSION}" \
  -t "${REGISTRY}/team2-gateway:latest" \
  .

echo "Build complete!"
echo ""
echo "To push images:"
echo "  docker push ${REGISTRY}/team2-backend:${VERSION}"
echo "  docker push ${REGISTRY}/team2-gateway:${VERSION}"
EOF

chmod +x build.sh

cat > deploy.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-your-registry.io/team2}"
VERSION="${VERSION:-0.0.1}"

echo "Deploying to OpenShift..."
echo "Registry: ${REGISTRY}"
echo "Version: ${VERSION}"

# Apply with kustomize
cd openshift
kustomize edit set image \
  "\${REGISTRY}/team2-backend=${REGISTRY}/team2-backend:${VERSION}" \
  "\${REGISTRY}/team2-gateway=${REGISTRY}/team2-gateway:${VERSION}"

kubectl apply -k .

echo "Deployment initiated!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n team2-demo"
echo "  kubectl get route -n team2-demo"
EOF

chmod +x deploy.sh

cat > dev.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Starting local development environment..."
echo ""
echo "This will start:"
echo "  - Backend on http://localhost:8080"
echo "  - Gateway on http://localhost:3000"
echo ""

docker-compose up --build
EOF

chmod +x dev.sh

# --- README -----------------------------------------------------
cat > README.md <<'EOF'
# Team 2 Demo Application - Optimized

A production-ready demo application with Spring Boot backend, Angular frontend, and Nginx gateway.

## Architecture

```
┌─────────────┐
│   Gateway   │ (Nginx + Angular SPA)
│   :8080     │
└──────┬──────┘
       │
       ├─── /      → Angular Frontend (static files)
       │
       └─── /api/  → Spring Boot Backend
                     └─ /hello
                     └─ /health
```

## Key Optimizations

- **Consolidated Gateway**: Single nginx container serves frontend AND proxies backend
- **Multi-stage Builds**: Optimized Docker images with dependency caching
- **Security**: Non-root users, security contexts, network policies
- **Health Checks**: Proper liveness/readiness probes
- **Resource Management**: Sensible CPU/memory limits
- **Development Workflow**: docker-compose for local development
- **Production Ready**: Rolling updates, multiple replicas, TLS routes

## Quick Start

### Local Development

```bash
# Start all services with docker-compose
./dev.sh

# Or manually:
# Terminal 1 - Backend
cd backend
mvn spring-boot:run

# Terminal 2 - Frontend (with proxy to backend)
cd frontend
npm install
npm start
```

Access:
- Frontend: http://localhost:4200
- Backend API: http://localhost:8080/api/hello

### Build Images

```bash
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

./build.sh
```

### Deploy to OpenShift

```bash
# Push images first
docker push ${REGISTRY}/team2-backend:${VERSION}
docker push ${REGISTRY}/team2-gateway:${VERSION}

# Deploy
./deploy.sh

# Check deployment
kubectl get pods -n team2-demo
kubectl get route -n team2-demo
```

## Project Structure

```
team2-demo-optimized/
├── backend/              # Spring Boot application
│   ├── src/
│   └── pom.xml
├── frontend/             # Angular application
│   ├── src/
│   ├── package.json
│   └── proxy.conf.json   # Dev proxy configuration
├── gateway/              # Nginx gateway configuration
│   ├── nginx.conf
│   └── 50x.html
├── docker/               # Docker build files
│   ├── Dockerfile.backend
│   └── Dockerfile.gateway
├── openshift/            # Kubernetes/OpenShift manifests
│   ├── backend-deployment.yaml
│   ├── gateway-deployment.yaml
│   ├── route.yaml
│   ├── network-policy.yaml
│   └── kustomization.yaml
├── docker-compose.yml    # Local development
├── build.sh              # Build images
├── deploy.sh             # Deploy to OpenShift
└── dev.sh                # Start local development
```

## Configuration

### Environment Variables

**Build & Deploy:**
- `REGISTRY`: Container registry URL (default: `your-registry.io/team2`)
- `VERSION`: Image version tag (default: `0.0.1`)

**Backend (application.yml):**
- `server.port`: HTTP port (default: 8080)
- `SPRING_PROFILES_ACTIVE`: Active profile (dev/docker/openshift)

### OpenShift Route

Edit `openshift/route.yaml` to set your cluster domain:
```yaml
spec:
  host: team2-demo.apps.your-cluster.com
```

## Development

### Frontend Proxy

During development, the frontend uses a proxy configuration (`proxy.conf.json`) to forward `/api` requests to the backend running on port 8080. This avoids CORS issues.

### Hot Reload

```bash
cd frontend
npm start  # Frontend with hot reload on :4200

cd backend
mvn spring-boot:run  # Backend with devtools on :8080
```

## Testing

### Test Backend
```bash
curl http://localhost:8080/api/hello
# Expected: {"message":"Hello from Spring Boot Backend"}
```

### Test Frontend
Visit http://localhost:4200 and click "Call Backend"

### Test Gateway (Docker)
```bash
docker-compose up
curl http://localhost:3000/api/hello
```

## Production Considerations

1. **Update Registry**: Replace `your-registry.io/team2` with actual registry
2. **Update Route Host**: Set proper domain in `openshift/route.yaml`
3. **CORS Configuration**: Update `@CrossOrigin` in backend for production domains
4. **Resource Limits**: Adjust based on actual load testing
5. **Replicas**: Scale based on traffic requirements
6. **Monitoring**: Add Prometheus/Grafana for metrics
7. **Logging**: Configure centralized logging (ELK/Splunk)

## Troubleshooting

### Build Issues
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

### Deployment Issues
```bash
# Check pod logs
kubectl logs -n team2-demo deployment/backend-team2
kubectl logs -n team2-demo deployment/gateway-team2

# Check pod status
kubectl describe pod -n team2-demo <pod-name>

# Test connectivity
kubectl exec -n team2-demo deployment/gateway-team2 -- wget -O- http://backend-team2:8080/api/hello
```

### CORS Issues
If frontend can't reach backend, verify:
1. Backend CORS configuration allows the frontend origin
2. Gateway proxy_pass configuration is correct
3. Network policies allow traffic between pods

## Security

- All containers run as non-root users
- Security contexts enforce non-privileged execution
- Network policies restrict pod-to-pod communication
- TLS termination at OpenShift route
- Security headers in nginx configuration

## License

MIT
EOF

echo ""
echo "✅ Optimized project structure created successfully in: ${BASE_DIR}"
echo ""
echo "Key improvements:"
echo "  - Consolidated gateway (nginx + frontend)"
echo "  - Multi-stage Docker builds with caching"
echo "  - Security: non-root users, network policies"
echo "  - docker-compose for local development"
echo "  - Proper health checks and resource limits"
echo "  - Build and deploy scripts"
echo ""
echo "Next steps:"
echo "  1. cd ${BASE_DIR}"
echo "  2. Update REGISTRY in build.sh and deploy.sh"
echo "  3. Run ./dev.sh for local development"
echo "  4. Run ./build.sh to build images"
echo "  5. Run ./deploy.sh to deploy to OpenShift"