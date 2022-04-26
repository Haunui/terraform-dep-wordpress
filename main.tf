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

  volumes {
    volume_name = "${var.prefix.vol}${each.value.name}"
    container_path = "${each.value.data_to_persist}"
  }

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

  volumes {
    volume_name = "${var.prefix.vol}${each.value.name}"
    container_path = "${each.value.data_to_persist}"
  }

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
