#!/usr/bin/env bash

set -e
set -u

USERNAME=""
PASSWORD=""
AMBARI_PORT=8443
CLUSTER_NAME=""

/var/lib/ambari-server/resources/scripts/configs.py \
    -l $(hostname -f) -t "$AMBARI_PORT" -s https \
    -n "$CLUSTER_NAME" -u "$USERNAME" -p "$PASSWORD" \
    -a set -c cluster-env \
    -k stack_root -v '{"HDF":"/usr/hdf"}'

/var/lib/ambari-server/resources/scripts/configs.py \
    -l $(hostname -f) -t "$AMBARI_PORT" -s https \
    -n "$CLUSTER_NAME" -u "$USERNAME" -p "$PASSWORD" \
    -a set -c cluster-env \
    -k stack_tools -v '
{
    "HDF": {
        "stack_selector": ["hdf-select","/usr/bin/hdf-select","hdf-select"],
        "conf_selector": ["conf-select","/usr/bin/conf-select","conf-select"]
    }
}' 

/var/lib/ambari-server/resources/scripts/configs.py \
    -l $(hostname -f) -t "$AMBARI_PORT" -s https \
    -n "$CLUSTER_NAME" -u "$USERNAME" -p "$PASSWORD" \
    -a set -c cluster-env -k stack_features -v '
{
  "HDF": {
    "stack_features": [
      {
        "name": "snappy",
        "description": "Snappy compressor/decompressor support",
        "min_version": "0.0.0.0",
        "max_version": "0.2.0.0"
      },
      {
        "name": "lzo",
        "description": "LZO libraries support",
        "min_version": "0.2.1.0"
      },
      {
        "name": "express_upgrade",
        "description": "Express upgrade support",
        "min_version": "0.1.0.0"
      },
      {
        "name": "rolling_upgrade",
        "description": "Rolling upgrade support",
        "min_version": "0.2.0.0"
      },
      {
        "name": "kafka_acl_migration_support",
        "description": "ACL migration support",
        "min_version": "2.3.4.0"
      },
      {
        "name": "config_versioning",
        "description": "Configurable versions support",
        "min_version": "0.3.0.0"
      },
      {
        "name": "datanode_non_root",
        "description": "DataNode running as non-root support (AMBARI-7615)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "remove_ranger_hdfs_plugin_env",
        "description": "HDFS removes Ranger env files (AMBARI-14299)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "ranger",
        "description": "Ranger Service support",
        "min_version": "0.2.0.0"
      },
      {
        "name": "ranger_tagsync_component",
        "description": "Ranger Tagsync component support (AMBARI-14383)",
        "min_version": "2.0.0.0"
      },
      {
        "name": "phoenix",
        "description": "Phoenix Service support",
        "min_version": "0.3.0.0"
      },
      {
        "name": "nfs",
        "description": "NFS support",
        "min_version": "0.3.0.0"
      },
      {
        "name": "tez_for_spark",
        "description": "Tez dependency for Spark",
        "min_version": "0.2.0.0",
        "max_version": "0.3.0.0"
      },
      {
        "name": "timeline_state_store",
        "description": "Yarn application timeline-service supports state store property (AMBARI-11442)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "copy_tarball_to_hdfs",
        "description": "Copy tarball to HDFS support (AMBARI-12113)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "spark_16plus",
        "description": "Spark 1.6+",
        "min_version": "1.2.0.0"
      },
      {
        "name": "spark_thriftserver",
        "description": "Spark Thrift Server",
        "min_version": "0.3.2.0"
      },
      {
        "name": "storm_kerberos",
        "description": "Storm Kerberos support (AMBARI-7570)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "storm_ams",
        "description": "Storm AMS integration (AMBARI-10710)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "create_kafka_broker_id",
        "description": "Ambari should create Kafka Broker Id (AMBARI-12678)",
        "min_version": "0.2.0.0",
        "max_version": "0.3.0.0"
      },
      {
        "name": "kafka_listeners",
        "description": "Kafka listeners (AMBARI-10984)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "kafka_kerberos",
        "description": "Kafka Kerberos support (AMBARI-10984)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "pig_on_tez",
        "description": "Pig on Tez support (AMBARI-7863)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "ranger_usersync_non_root",
        "description": "Ranger Usersync as non-root user (AMBARI-10416)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "ranger_audit_db_support",
        "description": "Ranger Audit to DB support",
        "min_version": "0.2.0.0",
        "max_version": "2.0.0.0"
      },
      {
        "name": "accumulo_kerberos_user_auth",
        "description": "Accumulo Kerberos User Auth (AMBARI-10163)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "knox_versioned_data_dir",
        "description": "Use versioned data dir for Knox (AMBARI-13164)",
        "min_version": "0.3.2.0"
      },
      {
        "name": "knox_sso_topology",
        "description": "Knox SSO Topology support (AMBARI-13975)",
        "min_version": "0.3.8.0"
      },
      {
        "name": "atlas_rolling_upgrade",
        "description": "Rolling upgrade support for Atlas",
        "min_version": "0.3.0.0"
      },
      {
        "name": "oozie_admin_user",
        "description": "Oozie install user as an Oozie admin user (AMBARI-7976)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "oozie_create_hive_tez_configs",
        "description": "Oozie create configs for Ambari Hive and Tez deployments (AMBARI-8074)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "oozie_setup_shared_lib",
        "description": "Oozie setup tools used to shared Oozie lib to HDFS (AMBARI-7240)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "oozie_host_kerberos",
        "description": "Oozie in secured clusters uses _HOST in Kerberos principal (AMBARI-9775)",
        "min_version": "0.0.0.0",
        "max_version": "0.2.0.0"
      },
      {
        "name": "falcon_extensions",
        "description": "Falcon Extension",
        "min_version": "2.0.0.0"
      },
      {
        "name": "hive_metastore_upgrade_schema",
        "description": "Hive metastore upgrade schema support (AMBARI-11176)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "hive_server_interactive",
        "description": "Hive server interactive support (AMBARI-15573)",
        "min_version": "2.0.0.0"
      },
      {
        "name": "hive_webhcat_specific_configs",
        "description": "Hive webhcat specific configurations support (AMBARI-12364)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "hive_purge_table",
        "description": "Hive purge table support (AMBARI-12260)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "hive_server2_kerberized_env",
        "description": "Hive server2 working on kerberized environment (AMBARI-13749)",
        "min_version": "0.2.3.0",
        "max_version": "0.2.5.0"
      },
      {
        "name": "hive_env_heapsize",
        "description": "Hive heapsize property defined in hive-env (AMBARI-12801)",
        "min_version": "0.2.0.0"
      },
      {
        "name": "ranger_kms_hsm_support",
        "description": "Ranger KMS HSM support (AMBARI-15752)",
        "min_version": "2.0.0.0"
      },
      {
        "name": "ranger_log4j_support",
        "description": "Ranger supporting log-4j properties (AMBARI-15681)",
        "min_version": "2.0.0.0"
      },
      {
        "name": "ranger_kerberos_support",
        "description": "Ranger Kerberos support",
        "min_version": "2.0.0.0"
      },
      {
        "name": "hive_metastore_site_support",
        "description": "Hive Metastore site support",
        "min_version": "2.0.0.0"
      },
      {
        "name": "ranger_usersync_password_jceks",
        "description": "Saving Ranger Usersync credentials in jceks",
        "min_version": "2.0.0.0"
      },
      {
        "name": "ranger_install_infra_client",
        "description": "Ambari Infra Service support",
        "min_version": "2.0.0.0"
      },
      {
        "name": "hbase_home_directory",
        "description": "Hbase home directory in HDFS needed for HBASE backup",
        "min_version": "2.0.0.0"
      },
      {
        "name": "spark_livy",
        "description": "Livy as slave component of spark",
        "min_version": "2.0.0.0"
      },
      {
        "name": "atlas_ranger_plugin_support",
        "description": "Atlas Ranger plugin support",
        "min_version": "2.0.0.0"
      },
      {
        "name": "atlas_conf_dir_in_path",
        "description": "Prepend the Atlas conf dir (/etc/atlas/conf) to the classpath of Storm and Falcon",
        "min_version": "0.3.0.0",
        "max_version": "0.4.99.99"
      },
      {
        "name": "atlas_upgrade_support",
        "description": "Atlas supports express and rolling upgrades",
        "min_version": "2.0.0.0"
      },
      {
        "name": "ranger_pid_support",
        "description": "Ranger Service support pid generation AMBARI-16756",
        "min_version": "2.0.0.0"
      },
      {
        "name": "ranger_kms_pid_support",
        "description": "Ranger KMS Service support pid generation",
        "min_version": "2.0.0.0"
      },
      {
        "name": "ranger_admin_password_change",
        "description": "Allow ranger admin credentials to be specified during cluster creation (AMBARI-17000)",
        "min_version": "2.0.0.0"
      },
      {
        "name": "storm_metrics_apache_classes",
        "description": "Metrics sink for Storm that uses Apache class names",
        "min_version": "2.0.0.0"
      },
      {
        "name": "toolkit_config_update",
        "description": "Support separate input and output for toolkit configuration",
        "min_version": "2.1.0.0"
      },
      {
        "name": "nifi_encrypt_config",
        "description": "Encrypt sensitive properties written to nifi property file",
        "min_version": "2.1.0.0"
      },
      {
        "name": "ranger_xml_configuration",
        "description": "Ranger code base support xml configurations",
        "min_version": "0.3.0.0"
      },
      {
        "name": "kafka_ranger_plugin_support",
        "description": "Ambari stack changes for Ranger Kafka Plugin (AMBARI-11299)",
        "min_version": "0.3.0.0"
      },
      {
        "name": "ranger_setup_db_on_start",
        "description": "Allows setup of ranger db and java patches to be called multiple times on each START",
        "min_version": "3.0.0.0"
      },
      {
        "name": "ranger_solr_config_support",
        "description": "Showing Ranger solrconfig.xml on UI",
        "min_version": "3.0.0.0"
      },
      {
        "name": "core_site_for_ranger_plugins",
        "description": "Adding core-site.xml in when Ranger plugin is enabled for Storm, Kafka, and Knox.",
        "min_version": "3.0.0.0"
      },
      {
        "name": "secure_ranger_ssl_password",
        "description": "Securing Ranger Admin and Usersync SSL and Trustore related passwords in jceks",
        "min_version": "3.0.0.0"
      },
      {
        "name": "tls_toolkit_san",
        "description": "Support subject alternative name flag",
        "min_version": "3.0.0.0"
      },
      {
        "name": "admin_toolkit_support",
        "description": "Supports the nifi admin toolkit",
        "min_version": "3.0.0.0"
      },
      {
        "name": "nifi_jaas_conf_create",
        "description": "Create NIFI jaas configuration when kerberos is enabled",
        "min_version": "3.0.0.0"
      },
      {"name": "registry_remove_rootpath","description": "Registry remove root path setting","min_version": "3.0.2.0"}]}}
'

/var/lib/ambari-server/resources/scripts/configs.py \
    -l $(hostname -f) -t "$AMBARI_PORT" -s https \
    -n "$CLUSTER_NAME" -u "$USERNAME" -p "$PASSWORD" \
    -a set -c cluster-env -k stack_packages -v '
{
  "HDF": {
    "stack-select": {
      "KAFKA": {
        "KAFKA_BROKER": {
          "STACK-SELECT-PACKAGE": "kafka-broker",
          "INSTALL": [
            "kafka-broker"
          ],
          "PATCH": [
            "kafka-broker"
          ],
          "STANDARD": [
            "kafka-broker"
          ]
        }
      },
      "RANGER": {
        "RANGER_ADMIN": {
          "STACK-SELECT-PACKAGE": "ranger-admin",
          "INSTALL": [
            "ranger-admin"
          ],
          "PATCH": [
            "ranger-admin"
          ],
          "STANDARD": [
            "ranger-admin"
          ]
        },
        "RANGER_TAGSYNC": {
          "STACK-SELECT-PACKAGE": "ranger-tagsync",
          "INSTALL": [
            "ranger-tagsync"
          ],
          "PATCH": [
            "ranger-tagsync"
          ],
          "STANDARD": [
            "ranger-tagsync"
          ]
        },
        "RANGER_USERSYNC": {
          "STACK-SELECT-PACKAGE": "ranger-usersync",
          "INSTALL": [
            "ranger-usersync"
          ],
          "PATCH": [
            "ranger-usersync"
          ],
          "STANDARD": [
            "ranger-usersync"
          ]
        }
      },
      "RANGER_KMS": {
        "RANGER_KMS_SERVER": {
          "STACK-SELECT-PACKAGE": "ranger-kms",
          "INSTALL": [
            "ranger-kms"
          ],
          "PATCH": [
            "ranger-kms"
          ],
          "STANDARD": [
            "ranger-kms"
          ]
        }
      },
      "STORM": {
        "NIMBUS": {
          "STACK-SELECT-PACKAGE": "storm-nimbus",
          "INSTALL": [
            "storm-client",
            "storm-nimbus"
          ],
          "PATCH": [
            "storm-client",
            "storm-nimbus"
          ],
          "STANDARD": [
            "storm-client",
            "storm-nimbus"
          ]
        },
        "SUPERVISOR": {
          "STACK-SELECT-PACKAGE": "storm-supervisor",
          "INSTALL": [
            "storm-supervisor"
          ],
          "PATCH": [
            "storm-supervisor"
          ],
          "STANDARD": [
            "storm-client",
            "storm-supervisor"
          ]
        },
        "DRPC_SERVER": {
          "STACK-SELECT-PACKAGE": "storm-client",
          "INSTALL": [
            "storm-client"
          ],
          "PATCH": [
            "storm-client"
          ],
          "STANDARD": [
            "storm-client"
          ]
        },
        "STORM_UI_SERVER": {
          "STACK-SELECT-PACKAGE": "storm-client",
          "INSTALL": [
            "storm-client"
          ],
          "PATCH": [
            "storm-client"
          ],
          "STANDARD": [
            "storm-client"
          ]
        }
      },
      "ZOOKEEPER": {
        "ZOOKEEPER_CLIENT": {
          "STACK-SELECT-PACKAGE": "zookeeper-client",
          "INSTALL": [
            "zookeeper-client"
          ],
          "PATCH": [
            "zookeeper-client"
          ],
          "STANDARD": [
            "zookeeper-client"
          ]
        },
        "ZOOKEEPER_SERVER": {
          "STACK-SELECT-PACKAGE": "zookeeper-server",
          "INSTALL": [
            "zookeeper-server"
          ],
          "PATCH": [
            "zookeeper-server"
          ],
          "STANDARD": [
            "zookeeper-server"
          ]
        }
      },
      "NIFI": {
        "NIFI_MASTER": {
          "STACK-SELECT-PACKAGE": "nifi",
          "INSTALL": [
            "nifi"
          ],
          "PATCH": [
            "nifi"
          ],
          "STANDARD": [
            "nifi"
          ]
        }
      },
        "REGISTRY": {
          "REGISTRY_SERVER": {
            "STACK-SELECT-PACKAGE": "registry",
            "INSTALL": [
              "registry"
            ],
            "PATCH": [
              "registry"
            ],
            "STANDARD": [
              "registry"
            ]
          }
        },
        "STREAMLINE": {
          "STREAMLINE_SERVER": {
            "STACK-SELECT-PACKAGE": "streamline",
            "INSTALL": [
              "streamline"
            ],
            "PATCH": [
              "streamline"
            ],
            "STANDARD": [
              "streamline"
            ]
          }
        }
      },
      "conf-select": {
        "kafka": [
          {
            "conf_dir": "/etc/kafka/conf",
            "current_dir": "{0}/current/kafka-broker/conf"
          }
        ],
        "nifi": [
          {
            "conf_dir": "/etc/nifi/conf",
            "current_dir": "{0}/current/nifi/conf"
          }
        ],
        "ranger-admin": [
          {
            "conf_dir": "/etc/ranger/admin/conf",
            "current_dir": "{0}/current/ranger-admin/conf"
          }
        ],
        "ranger-kms": [
          {
            "conf_dir": "/etc/ranger/kms/conf",
            "current_dir": "{0}/current/ranger-kms/conf"
          }
        ],
        "ranger-tagsync": [
          {
            "conf_dir": "/etc/ranger/tagsync/conf",
            "current_dir": "{0}/current/ranger-tagsync/conf"
          }
        ],
        "ranger-usersync": [
          {
            "conf_dir": "/etc/ranger/usersync/conf",
            "current_dir": "{0}/current/ranger-usersync/conf"
          }
        ],
        "storm": [
          {
            "conf_dir": "/etc/storm/conf",
            "current_dir": "{0}/current/storm-client/conf"
          }
        ],
        "storm-slider-client": [
          {
            "conf_dir": "/etc/storm-slider-client/conf",
            "current_dir": "{0}/current/storm-slider-client/conf"
          }
        ],
        "zookeeper": [
          {
            "conf_dir": "/etc/zookeeper/conf",
            "current_dir": "{0}/current/zookeeper-client/conf"
          }
        ]
      }
    }
  }
'
