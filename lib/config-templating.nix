# Configuration Templating System for ATproto Services
# Provides dynamic configuration generation with service discovery integration
{ lib, pkgs, ... }:

with lib;

rec {
  # Template variable types
  variableTypes = {
    string = "string";
    number = "number";
    boolean = "boolean";
    array = "array";
    object = "object";
    service = "service";  # Special type for service references
  };

  # Create configuration template
  mkConfigTemplate = {
    name,
    description ? "",
    template,
    variables ? {},
    outputFormat ? "json",
    validation ? {},
    ...
  }@args:
    let
      supportedFormats = [ "json" "yaml" "toml" "env" "ini" ];
      validFormat = builtins.elem outputFormat supportedFormats;
    in
    if !validFormat then
      throw "Invalid output format: ${outputFormat}. Supported: ${builtins.toString supportedFormats}"
    else
    {
      inherit name description template variables outputFormat validation;
      
      # Variable validation
      validateVariables = vars:
        let
          validateVar = varName: varConfig:
            let
              varType = varConfig.type or "string";
              varValue = vars.${varName} or varConfig.default or null;
              required = varConfig.required or false;
            in
            {
              name = varName;
              valid = if required then varValue != null else true;
              error = if required && varValue == null then
                "Required variable '${varName}' is missing"
              else null;
            };
          
          results = mapAttrsToList validateVar variables;
          errors = builtins.filter (r: r.error != null) results;
        in
        {
          valid = errors == [];
          errors = map (e: e.error) errors;
        };
      
      # Template processing
      processTemplate = vars:
        let
          # Service discovery variable resolution
          resolveServiceVars = templateStr: discoveredServices:
            let
              servicePattern = "\\$\\{service\\.([^.]+)\\.([^}]+)\\}";
              replaceServiceVar = match:
                let
                  serviceName = builtins.elemAt match 0;
                  property = builtins.elemAt match 1;
                  service = discoveredServices.${serviceName} or null;
                in
                if service != null then
                  toString (service.${property} or "")
                else
                  "";
            in
            builtins.replaceStrings 
              (builtins.match servicePattern templateStr)
              (map replaceServiceVar (builtins.match servicePattern templateStr))
              templateStr;
          
          # Standard variable substitution
          substituteVars = templateStr: variables:
            builtins.foldl' (acc: varName:
              let
                varValue = variables.${varName} or "";
                placeholder = "\${${varName}}";
              in
              builtins.replaceStrings [placeholder] [toString varValue] acc
            ) templateStr (builtins.attrNames variables);
          
          # Process template with both service and standard variables
          processedTemplate = 
            substituteVars 
              (resolveServiceVars template (vars.discoveredServices or {}))
              vars;
        in
        processedTemplate;
      
      # Format-specific output generation
      generateOutput = processedContent:
        if outputFormat == "json" then
          # Validate and format JSON
          let
            parsed = builtins.fromJSON processedContent;
          in
          builtins.toJSON parsed
        else if outputFormat == "env" then
          # Convert to environment variable format
          let
            lines = splitString "\n" processedContent;
            envLines = map (line:
              if builtins.match "^[A-Za-z_][A-Za-z0-9_]*=.*" line != null then
                line
              else
                ""
            ) lines;
          in
          concatStringsSep "\n" (builtins.filter (x: x != "") envLines)
        else if outputFormat == "ini" then
          # Basic INI format processing
          processedContent
        else
          # Pass through for yaml/toml (would need external processors)
          processedContent;
    };

  # Pre-defined templates for common ATproto configurations
  
  # PDS configuration template
  pdsConfigTemplate = mkConfigTemplate {
    name = "pds-config";
    description = "Personal Data Server configuration";
    outputFormat = "env";
    
    template = ''
      # PDS Configuration
      PDS_HOSTNAME=$${hostname}
      PDS_PORT=$${port}
      PDS_DATA_DIRECTORY=$${dataDir}
      
      # Database Configuration
      PDS_DATABASE_URL=$${database.url}
      PDS_DATABASE_MIGRATE=$${database.autoMigrate}
      
      # ATproto Network Configuration
      PDS_DID_PLC_URL=$${service.plc.url}
      PDS_BSKY_APP_VIEW_URL=$${service.appview.url}
      PDS_BSKY_APP_VIEW_DID=$${service.appview.did}
      
      # Authentication
      PDS_JWT_SECRET=$${auth.jwtSecret}
      PDS_ADMIN_PASSWORD=$${auth.adminPassword}
      
      # Optional Services
      PDS_IMG_URI_SALT=$${image.uriSalt}
      PDS_IMG_URI_KEY=$${image.uriKey}
      PDS_EMAIL_SMTP_URL=$${email.smtpUrl}
      
      # Moderation
      PDS_MOD_SERVICE_URL=$${service.moderation.url}
      PDS_MOD_SERVICE_DID=$${service.moderation.did}
    '';
    
    variables = {
      hostname = { type = "string"; required = true; };
      port = { type = "number"; default = 3000; };
      dataDir = { type = "string"; default = "/var/lib/pds"; };
      
      database = {
        type = "object";
        required = true;
        properties = {
          url = { type = "string"; required = true; };
          autoMigrate = { type = "boolean"; default = true; };
        };
      };
      
      auth = {
        type = "object";
        required = true;
        properties = {
          jwtSecret = { type = "string"; required = true; };
          adminPassword = { type = "string"; required = true; };
        };
      };
      
      image = {
        type = "object";
        properties = {
          uriSalt = { type = "string"; };
          uriKey = { type = "string"; };
        };
      };
      
      email = {
        type = "object";
        properties = {
          smtpUrl = { type = "string"; };
        };
      };
    };
  };
  
  # AppView configuration template
  appviewConfigTemplate = mkConfigTemplate {
    name = "appview-config";
    description = "AppView service configuration";
    outputFormat = "json";
    
    template = ''
      {
        "service": {
          "port": $${port},
          "hostname": "$${hostname}"
        },
        "database": {
          "url": "$${database.url}",
          "pool": {
            "size": $${database.poolSize},
            "maxOverflow": $${database.maxOverflow}
          }
        },
        "atproto": {
          "pds": {
            "url": "$${service.pds.url}",
            "did": "$${service.pds.did}"
          },
          "plc": {
            "url": "$${service.plc.url}"
          }
        },
        "feeds": {
          "generators": [
            $${feeds.generators}
          ]
        },
        "moderation": {
          "labelers": [
            $${moderation.labelers}
          ]
        }
      }
    '';
    
    variables = {
      hostname = { type = "string"; required = true; };
      port = { type = "number"; default = 3000; };
      
      database = {
        type = "object";
        required = true;
        properties = {
          url = { type = "string"; required = true; };
          poolSize = { type = "number"; default = 10; };
          maxOverflow = { type = "number"; default = 20; };
        };
      };
      
      feeds = {
        type = "object";
        properties = {
          generators = { type = "array"; default = []; };
        };
      };
      
      moderation = {
        type = "object";
        properties = {
          labelers = { type = "array"; default = []; };
        };
      };
    };
  };
  
  # Relay configuration template
  relayConfigTemplate = mkConfigTemplate {
    name = "relay-config";
    description = "Relay service configuration";
    outputFormat = "toml";
    
    template = ''
      [service]
      hostname = "$${hostname}"
      port = $${port}
      
      [database]
      url = "$${database.url}"
      max_connections = $${database.maxConnections}
      
      [atproto]
      did = "$${atproto.did}"
      signing_key_file = "$${atproto.signingKeyFile}"
      
      [firehose]
      max_buffer_size = $${firehose.maxBufferSize}
      compression = "$${firehose.compression}"
      
      [subscription]
      max_concurrent = $${subscription.maxConcurrent}
      timeout_seconds = $${subscription.timeoutSeconds}
      
      [[upstream_pdses]]
      url = "$${service.pds.url}"
      did = "$${service.pds.did}"
    '';
    
    variables = {
      hostname = { type = "string"; required = true; };
      port = { type = "number"; default = 3001; };
      
      database = {
        type = "object";
        required = true;
        properties = {
          url = { type = "string"; required = true; };
          maxConnections = { type = "number"; default = 100; };
        };
      };
      
      atproto = {
        type = "object";
        required = true;
        properties = {
          did = { type = "string"; required = true; };
          signingKeyFile = { type = "string"; required = true; };
        };
      };
      
      firehose = {
        type = "object";
        properties = {
          maxBufferSize = { type = "number"; default = 1000000; };
          compression = { type = "string"; default = "zstd"; };
        };
      };
      
      subscription = {
        type = "object";
        properties = {
          maxConcurrent = { type = "number"; default = 100; };
          timeoutSeconds = { type = "number"; default = 30; };
        };
      };
    };
  };

  # Configuration template registry
  templateRegistry = {
    pds = pdsConfigTemplate;
    appview = appviewConfigTemplate;
    relay = relayConfigTemplate;
  };

  # Template processing utilities
  
  # Process template with service discovery
  processTemplateWithDiscovery = template: variables: discoveredServices:
    let
      # Merge discovered services into variables
      enrichedVars = variables // {
        discoveredServices = discoveredServices;
      };
      
      # Validate variables
      validation = template.validateVariables enrichedVars;
    in
    if !validation.valid then
      throw "Template validation failed: ${builtins.toString validation.errors}"
    else
      let
        processedContent = template.processTemplate enrichedVars;
      in
      template.generateOutput processedContent;

  # Generate configuration files for a service stack
  generateStackConfigs = { services, templates, discoveredServices ? {}, outputDir ? "/etc/atproto" }:
    let
      generateServiceConfig = serviceName: serviceConfig:
        let
          templateName = serviceConfig.template or serviceName;
          template = templates.${templateName} or (throw "Template '${templateName}' not found");
          
          configContent = processTemplateWithDiscovery 
            template 
            serviceConfig.variables 
            discoveredServices;
          
          filename = "${serviceName}.${template.outputFormat}";
        in
        {
          "${outputDir}/${filename}" = {
            text = configContent;
            mode = "0640";
            user = serviceConfig.user or "root";
            group = serviceConfig.group or "root";
          };
        };
    in
    lib.mkMerge (lib.mapAttrsToList generateServiceConfig services);

  # Dynamic configuration update system
  mkDynamicConfig = { 
    template, 
    variables, 
    watchPaths ? [], 
    reloadCommand ? null,
    ...
  }@args:
    {
      inherit template variables watchPaths reloadCommand;
      
      # Generate systemd path units for watching configuration changes
      pathUnits = lib.listToAttrs (map (path: {
        name = "atproto-config-watch-${baseNameOf path}";
        value = {
          description = "Watch ${path} for configuration changes";
          wantedBy = [ "multi-user.target" ];
          
          pathConfig = {
            PathChanged = path;
            Unit = "atproto-config-reload.service";
          };
        };
      }) watchPaths);
      
      # Configuration reload service
      reloadService = {
        "atproto-config-reload" = {
          description = "Reload ATproto configuration";
          
          serviceConfig = {
            Type = "oneshot";
            ExecStart = if reloadCommand != null then
              reloadCommand
            else
              "${pkgs.systemd}/bin/systemctl reload-or-restart atproto-*.service";
          };
        };
      };
    };

  # Configuration validation utilities
  
  # Validate service configuration against schema
  validateServiceConfig = schema: config:
    let
      validateProperty = propName: propSchema: propValue:
        let
          propType = propSchema.type or "string";
          required = propSchema.required or false;
          hasValue = propValue != null;
        in
        {
          property = propName;
          valid = if required then hasValue else true;
          typeValid = if hasValue then
            (propType == "string" && builtins.isString propValue) ||
            (propType == "number" && builtins.isInt propValue) ||
            (propType == "boolean" && builtins.isBool propValue) ||
            (propType == "array" && builtins.isList propValue) ||
            (propType == "object" && builtins.isAttrs propValue)
          else true;
        };
      
      results = lib.mapAttrsToList (propName: propSchema:
        validateProperty propName propSchema (config.${propName} or null)
      ) schema;
      
      errors = builtins.filter (r: !r.valid || !r.typeValid) results;
    in
    {
      valid = errors == [];
      errors = map (e: 
        if !e.valid then
          "Required property '${e.property}' is missing"
        else
          "Property '${e.property}' has invalid type"
      ) errors;
    };

  # Generate NixOS configuration from templates
  mkTemplatedConfig = { serviceName, template, variables, discoveredServices ? {} }:
    let
      configContent = processTemplateWithDiscovery template variables discoveredServices;
      
      configFile = pkgs.writeText "${serviceName}-config.${template.outputFormat}" configContent;
    in
    {
      environment.etc."atproto/${serviceName}.${template.outputFormat}" = {
        source = configFile;
        mode = "0640";
      };
      
      # Make config file available to the service
      systemd.services."atproto-${serviceName}" = {
        environment = {
          ATPROTO_CONFIG_FILE = "/etc/atproto/${serviceName}.${template.outputFormat}";
        };
      };
    };
}