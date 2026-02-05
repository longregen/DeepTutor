# Module for DeepTutor
# Usage in your configuration.nix:
#   imports = [ deeptutor.nixosModules.default ];
#   services.deeptutor.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.deeptutor;

  # Import Python packages
  pythonPackagesOverlay = import ../python-packages/overlay.nix {prev = pkgs;};
  pythonPackagesList = import ../python-packages/packages.nix;

  python = pkgs.python311.override {
    packageOverrides = pythonPackagesOverlay;
  };

  pythonEnv = python.withPackages pythonPackagesList;

  # Build the Next.js frontend
  frontendPackage = import ../frontend.nix {
    inherit pkgs;
    src = "${cfg.sourceDir}/web";
    apiBase = cfg.frontend.apiBase;
  };

  # Environment file generation
  envFile = pkgs.writeText "deeptutor.env" ''
# Server Configuration
BACKEND_PORT=${toString cfg.backend.port}
FRONTEND_PORT=${toString cfg.frontend.port}
DEEPTUTOR_DATA_DIR=${cfg.dataDir}
# LLM Configuration
LLM_BINDING=${cfg.llm.binding}
LLM_MODEL=${cfg.llm.model}
LLM_HOST=${cfg.llm.host}
# Embedding Configuration
EMBEDDING_BINDING=${cfg.embedding.binding}
EMBEDDING_MODEL=${cfg.embedding.model}
EMBEDDING_DIMENSION=${toString cfg.embedding.dimension}
EMBEDDING_HOST=${cfg.embedding.host}
# Search Configuration
SEARCH_PROVIDER=${cfg.search.provider}
# Logging
RAG_TOOL_MODULE_LOG_LEVEL=${cfg.logLevel}
'';
  # Secrets are loaded separately via EnvironmentFile
in {
  options.services.deeptutor = {
    enable = mkEnableOption "DeepTutor AI-powered learning assistant";

    package = mkOption {
      type = types.package;
      default = pkgs.deeptutor or null;
      defaultText = literalExpression "pkgs.deeptutor";
      description = "The DeepTutor package to use (or null to use source directory)";
    };

    sourceDir = mkOption {
      type = types.path;
      default = ../..;
      description = "Path to DeepTutor source directory";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/deeptutor";
      description = "Directory for DeepTutor data (knowledge bases, logs, etc.)";
    };

    user = mkOption {
      type = types.str;
      default = "deeptutor";
      description = "User under which DeepTutor runs";
    };

    group = mkOption {
      type = types.str;
      default = "deeptutor";
      description = "Group under which DeepTutor runs";
    };

    # Backend configuration
    backend = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the FastAPI backend service";
      };

      port = mkOption {
        type = types.port;
        default = 8001;
        description = "Port for the backend API";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host to bind the backend to";
      };

      workers = mkOption {
        type = types.int;
        default = 1;
        description = "Number of uvicorn workers";
      };
    };

    # Frontend configuration
    frontend = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the Next.js frontend service";
      };

      port = mkOption {
        type = types.port;
        default = 3782;
        description = "Port for the frontend";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host to bind the frontend to";
      };

      apiBase = mkOption {
        type = types.str;
        default = "";
        example = "http://localhost:8001";
        description = ''
          API base URL for the frontend to use.
          Empty string (default) = same-origin, API served at /api on same domain.
          Set to full URL for cross-origin development or separate API domain.
        '';
      };
    };

    # LLM configuration
    llm = {
      binding = mkOption {
        type = types.enum ["openai" "azure_openai" "ollama" "lollms"];
        default = "openai";
        description = "LLM service provider type";
      };

      model = mkOption {
        type = types.str;
        default = "";
        example = "gpt-4o";
        description = "LLM model name";
      };

      host = mkOption {
        type = types.str;
        default = "";
        example = "https://api.openai.com/v1";
        description = "LLM API endpoint URL";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/deeptutor-llm-api-key";
        description = "File containing the LLM API key";
      };
    };

    # Embedding configuration
    embedding = {
      binding = mkOption {
        type = types.enum ["openai" "azure_openai" "ollama" "lollms"];
        default = "openai";
        description = "Embedding service provider type";
      };

      model = mkOption {
        type = types.str;
        default = "text-embedding-3-large";
        description = "Embedding model name";
      };

      dimension = mkOption {
        type = types.int;
        default = 3072;
        description = "Embedding vector dimension";
      };

      host = mkOption {
        type = types.str;
        default = "";
        description = "Embedding API endpoint URL";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/deeptutor-embedding-api-key";
        description = "File containing the embedding API key";
      };
    };

    # Search configuration
    search = {
      provider = mkOption {
        type = types.enum ["perplexity" "baidu" "kagi"];
        default = "perplexity";
        description = "Web search provider";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "File containing the search API key";
      };
    };

    # Logging
    logLevel = mkOption {
      type = types.enum ["DEBUG" "INFO" "WARNING" "ERROR"];
      default = "INFO";
      description = "Log level for RAG tool module";
    };

    # Firewall
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for DeepTutor services";
    };

    # Additional environment variables
    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {
        DISABLE_SSL_VERIFY = "false";
      };
      description = "Additional environment variables";
    };

    # Secrets file (for API keys)
    secretsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/deeptutor-secrets";
      description = ''
        File containing secret environment variables (API keys).
        Format: KEY=value, one per line.
        Should contain: LLM_API_KEY, EMBEDDING_API_KEY, etc.
      '';
    };

    # Nginx configuration
    nginx = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable nginx virtual host for DeepTutor";
      };

      domain = mkOption {
        type = types.str;
        default = "localhost";
        example = "deeptutor.example.com";
        description = "Domain name for the DeepTutor service";
      };

      enableSSL = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSL with ACME (Let's Encrypt)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "DeepTutor service user";
    };

    users.groups.${cfg.group} = {};

    # Create data directories
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/user 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/user/logs 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/knowledge_bases 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/config 0750 ${cfg.user} ${cfg.group} -"
    ] ++ optionals cfg.frontend.enable [
      "d ${cfg.dataDir}/frontend 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/frontend/.next 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/frontend/.next/cache 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/frontend/.next/cache/images 0750 ${cfg.user} ${cfg.group} -"
    ];

    # Backend systemd service
    systemd.services.deeptutor-backend = mkIf cfg.backend.enable {
      description = "DeepTutor Backend API";
      after = ["network.target" "systemd-tmpfiles-setup.service"];
      requires = ["systemd-tmpfiles-setup.service"];
      wantedBy = ["multi-user.target"];

      path = [ pythonEnv ];

      environment =
        {
          PYTHONPATH = "${cfg.sourceDir}";
          DEEPTUTOR_DATA_DIR = cfg.dataDir;
          DEEPTUTOR_CONFIG_DIR = "${cfg.dataDir}/config";
          BACKEND_PORT = toString cfg.backend.port;
          BACKEND_HOST = cfg.backend.host;
        }
        // cfg.extraEnv;

      # Copy config files on first start if they don't exist
      script = ''
        # Ensure config directory exists
        mkdir -p "${cfg.dataDir}/config"

        # Copy config files to writable location on first start
        if [ ! -f "${cfg.dataDir}/config/main.yaml" ]; then
          echo "Initializing config files in ${cfg.dataDir}/config/"
          cp ${cfg.sourceDir}/config/*.yaml ${cfg.dataDir}/config/
          chmod 640 ${cfg.dataDir}/config/*.yaml
        fi

        exec ${pythonEnv}/bin/uvicorn src.api.main:app \
          --host ${cfg.backend.host} \
          --port ${toString cfg.backend.port} \
          --workers ${toString cfg.backend.workers} \
          --proxy-headers \
          --forwarded-allow-ips="*"
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.sourceDir;
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [cfg.dataDir];
        ReadOnlyPaths = [cfg.sourceDir];

        # Environment files
        EnvironmentFile =
          [
            envFile
          ]
          ++ optional (cfg.secretsFile != null) cfg.secretsFile;
      };
    };

    # Frontend systemd service
    systemd.services.deeptutor-frontend = mkIf cfg.frontend.enable {
      description = "DeepTutor Frontend";
      after = ["network.target" "systemd-tmpfiles-setup.service" "deeptutor-backend.service"];
      requires = ["systemd-tmpfiles-setup.service"];
      wants = ["deeptutor-backend.service"];
      wantedBy = ["multi-user.target"];

      environment =
        {
          PORT = toString cfg.frontend.port;
          HOST = cfg.frontend.host;
          NEXT_PUBLIC_API_BASE = "http://${cfg.backend.host}:${toString cfg.backend.port}";
          NODE_ENV = "production";
        }
        // cfg.extraEnv;

      script = ''
        # Ensure frontend directory exists
        mkdir -p "${cfg.dataDir}/frontend"

        # Copy package to writable directory (only if changed)
        if [ ! -f "${cfg.dataDir}/frontend/.package-hash" ] || \
           [ "$(cat ${cfg.dataDir}/frontend/.package-hash 2>/dev/null)" != "${frontendPackage}" ]; then
          rm -rf ${cfg.dataDir}/frontend/*
          cp -r ${frontendPackage}/. ${cfg.dataDir}/frontend/
          chmod -R u+w ${cfg.dataDir}/frontend
          echo "${frontendPackage}" > ${cfg.dataDir}/frontend/.package-hash
        fi
        cd ${cfg.dataDir}/frontend
        exec ${pkgs.nodejs_20}/bin/node node_modules/next/dist/bin/next start -p ${toString cfg.frontend.port} -H ${cfg.frontend.host}
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [cfg.dataDir];

        # Environment files
        EnvironmentFile = optional (cfg.secretsFile != null) cfg.secretsFile;
      };
    };

    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts =
        (optional cfg.backend.enable cfg.backend.port)
        ++ (optional cfg.frontend.enable cfg.frontend.port);
    };

    # Nginx virtual host - serves frontend and proxies /api to backend
    services.nginx = mkIf cfg.nginx.enable {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts.${cfg.nginx.domain} = {
        forceSSL = cfg.nginx.enableSSL;
        enableACME = cfg.nginx.enableSSL;

        locations."/" = mkIf cfg.frontend.enable {
          proxyPass = "http://${cfg.frontend.host}:${toString cfg.frontend.port}";
          proxyWebsockets = true;
        };

        locations."/api" = mkIf cfg.backend.enable {
          proxyPass = "http://${cfg.backend.host}:${toString cfg.backend.port}";
          proxyWebsockets = true;
        };
      };
    };

    # Assertions
    assertions = [
      {
        assertion = cfg.backend.enable || cfg.frontend.enable;
        message = "At least one of services.deeptutor.backend.enable or services.deeptutor.frontend.enable must be true";
      }
    ];
  };
}
