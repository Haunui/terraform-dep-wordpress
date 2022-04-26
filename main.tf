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

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.16.0"
    }
  }
}

provider "docker" {
  host = "tcp://192.168.0.40:2375"
}

resource "docker_network" "net0" {
  for_each = var.network
  name = "${each.value.name}"
}

resource "docker_volume" "vol0" {
  for_each = local.containers
  name = "${var.prefix.vol}${each.value.name}"
}

resource "docker_image" "img0" {
  for_each = local.containers
  name = "${each.value.image}"
}

resource "docker_container" "cont0" {
  for_each = var.container.loader0
  image = docker_image.img0["${each.value.name}"].latest
  name = "${var.prefix.cont}${each.value.name}"
  env = local.cont0["${each.key}"].env

  networks_advanced {
    name = "${each.value.network.name}"
  }

  dynamic "ports" {
    for_each = each.value.ports
    
    content {
      internal = ports.value.int
      external = ports.value.ext
    }
  }
}

resource "docker_container" "cont1" {
  for_each = var.container.loader1
  image = docker_image.img0["${each.value.name}"].latest
  name = "${var.prefix.cont}${each.value.name}"
  env = local.cont1["${each.key}"].env

  networks_advanced {
    name = "${each.value.network.name}"
  }

  dynamic "ports" {
    for_each = each.value.ports
    
    content {
      internal = ports.value.int
      external = ports.value.ext
    }
  }
}
