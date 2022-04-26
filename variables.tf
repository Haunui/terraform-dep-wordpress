variable "prefix" {
  type = map
  default = {
    cont = ""
    vol = "v-"
    img = "i-"
    net = "n-"
  }
}

variable "network" {
  type = any
  default = {
    "net0" = {
      name = "net0"
      driver = "bridge"
      subnet = "172.22.0.0/24"
    }
  }
}

variable "container" {
  type = any
  default = {
    loader0 = {
      mariadb = {
        name = "mariadb"
        image = "mariadb:latest"
        data_to_persist = "/var/lib/mysql"
        ports = {}
        network = {
          name = "net0"
        }
      }
    }
    
    loader1 = {
      wordpress = {
        name = "wordpress"
        image = "wordpress:latest"
        data_to_persist = "/var/www/html"
        ports = {
          "0" = {
            int = 80
            ext = 80
          }
        }
        network = {
          name = "net0"
        }
      }
    }
  }
}

locals {
  containers = merge(var.container.loader0, var.container.loader1)
  cont0 = {
    mariadb = {
      env = [
        "MARIADB_USER=wordpress",
        "MARIADB_PASSWORD=password",
        "MARIADB_DATABASE=wordpress",
        "MARIADB_ROOT_PASSWORD=password"
      ]
    }
  }
  cont1 = {
    wordpress = {
      env = [
        "WORDPRESS_DB_HOST=${docker_container.cont0["mariadb"].ip_address}",
        "WORDPRESS_DB_USER=wordpress",
        "WORDPRESS_DB_PASSWORD=password",
        "WORDPRESS_DB_NAME=wordpress"
      ]
    }
  }
}

