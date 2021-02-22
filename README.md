# Docker

### Основные понятия

**Контейнер** - один или несколько linux-процессов, запущенных в изолированном окружении. 
Это значит, что некоторые части операционной системы с точки зрения этих запущенных процессов 
воспринимаются особенным образом, таким образом, который контролируется системой контейнеризации,
а не самой операционной системой.
**Docker image** - правила, по которым будут создаваться контейнеры с помощью
данного образа.
**Docker container** - инстанс docker image.
**Реестр Docker** — удалённое хранилище образов (по умолчанию используется Docker Hub)
**Тома Docker** — это файловая система, которая расположена на хост-машине за пределами контейнеров. 
Созданием и управлением томами занимается Docker. Вот основные свойства томов Docker:
* Они представляют собой средства для постоянного хранения информации
* Они самостоятельны и отделены от контейнеров
* Ими могут совместно пользоваться разные контейнеры
* Они позволяют организовать эффективное чтение и запись данных
* Их можно шифровать
* Им можно давать имена
* Они удобны для тестирования

**Docker Compose** — технология, упрощающая работу с многоконтейнерными приложениями.
**Docker Swarm** — средство для управления развёртыванием контейнеров.

Режимы запуска контейнеров:
1) Жизненный цикл контейнера равен жизненному циклу программы, запущенной внутри
2) Режим демона (ключ -d), подходит для программ, которые работают как сервисы.
3) Интерактивный режим, пример запуска: 
```shell
docker run --rm -it ubuntu:14.04
```
* ключ --rm: контейнер отключится после завершения главного процесса
* ключ --it (interactive, terminal): запустит контейнер в интерактивном режиме 
с терминалом в качестве точки входа

### Работа с файлами в контейнерах Docker

Файловая система контейнера состоит из большого кол-ва слоев (layered file system), 
при этом слой контейнера доступен как для чтения так и для записи, 
а слой образа доступен только для чтения. Layered file system использует при работе со слоями 
принцип сopy-on-write т.е в момент изменения файла создается его копия, в которую вносятся 
изменения, а первоначальный файл сохраняется в слое образа

Что происходит при попытке чтения файла из слоя образа: 
* Union File System (вспомогательная файловая система, производящая 
  каскадно-объединенное монтирование других файловых систем) ищет данный файл, 
  начиная со слоя контейнера и далее в слоях образа.

Что происходит при попытке записи в файл из слоя образа: 
* Так как файлы из слоя образа являются неизменяемыми 
  то мы не можем напрямую писать в файл слоя образа
* Copy-on-write: создается копия файла или части файла, 
  которая размещается в слое контейнера и в нее вносятся изменения
* При удалении файла создается специальный файл в слое контейнера, который указывает на то, 
  что файл удален и Union File System не показывает удаленный файл пользователю 

При такой реализации доступа к файлам чтение и запись замедляются. 
Насколько медленными будут эти процессы, зависит от конкретной реализации Union File System

Рекомендация: не хранить персистентные (требующие более долго хранения) данные
в слое контейнера

Контейнер может взаимодействовать с файловой системой хоста 
как на чтение, так и на запись. Для монтирования файлов с хоста внутрь контейнера
используется команда: 

```shell script
docker run -v {путь в файловой системе хоста}:{путь внутри контейнера}:{права доступа}
```
или
```shell script
docker run -mount {путь в файловой системе хоста}:{путь внутри контейнера}:{права доступа}
```

В контейнерах Docker организовать работу с данными можно тремя способами:

* Bind mount - файл или директория хоста копируется внутрь контейнера. На файл или папку ссылается его абсолютный путь 
  на машине хоста. Минусы: зависимость от файловой системы хоста, другие процессы могут внести изменения 
  в хранящиеся на хосте файлы
* Tmpfs (только на Linux) - использует оперативную память хоста. Это позволит ускорить выполнение операций по записи
  и чтению данных, но после завершения работы контейнера файлы удаляются. 
* Data volume - рекомендуемый способ хранения данных, используют для хранения тома Docker. Фактически, 
  файлы в этом случае также хранятся в директориях хоста, но Docker определяет путь хранения самостоятельно. 
  Как и в случае с монтированием директорий хоста, файлы и директории в data volumes сохраняются после завершения работы 
  контейнера.

*Data Volume Containers* - создается отдельный контейнер, с примонтированными к нему
data volumes, после чего можно использовать тома из этого контейнера. 

Такой подход удобен в случае если нам нужно обеспечить возможность работать с данными
из нескольких контейнеров или персистентных данных.

Пример:
```shell script
docker create -v /srv --name store ubuntu:14.04 /bin/true
docker run -it --rm --volumes-from store ubuntu:14.04
```


### Организация взаимодействия между контейнерами

Способы организации взаимодействия:
1) С помощью портов: 
```shell script
docker run -d --name port-export -p <port_on_host_machine>:<port_inside_container> image
```

2) С помощью терминала (удобно для отладки):
К уже запущенному контейнеру можно подключиться, использовав команду:
```shell script
docker exec -it <container-name> bash
```

3) Сетевое взаимодействие: 
В докере по умолчанию предопределены три сети: 
* **none** - сетевой стек специфичен для данного контейнера и взаимодействие 
с другими контейнерами невозможно. Используется для изоляции контейнера
* **host** - сетевое устройство хоста полностью переносится в контейнер
* **bridge** - по-умолчанию все контейнеры попадают в эту сеть и получают свой ip адрес.
В этой сети невозможно взаимодействие контейнеров по их имени, только по ip адресу.
Также данная сеть не обеспечивает изоляцию, так как все контейнеры по умолчанию попадают в эту сеть.

Команда показывающая список доступных сетей: 
```shell script
docker network ls
```

Для создания собственной сети используется команда: 
```shell script
docker network create custom
```

Для просмотра параметров созданной кастомной сети используется команда: 
```shell
docker network inspect custom
```

Для подключения контейнера к сети используется параметр --network: 
```shell script
docker run --network=custom
```

### Способы создания Docker-образов

1) Создание образа из контейнера: 
```shell
docker run -it --name image-from-container ubuntu:14.04
# внутри контейнера
  cd root
  echo mytext > test
  exit
docker commit image-from-container myimage
docker run -it --rm myimage
docker history myimage
```

У команды docker commit существует флаг --change для внесения изменений в сохраняемый образ, пример:
```shell
docker commit --change='ENTRYPOINT ["/usr/bin/python3"]' image-from-container myimage
```

2) Создание образа с помощью Dockerfile:
```dockerfile
FROM ubuntu:14.04

LABEL maintainer='Sharafutdinov Ruslan'

ENTRYPOINT '/usr/bin/python3'
```

Сборка образа: 
```shell
docker build -t image-from-dockerfile .
docker run -it --rm image-from-dockerfile
```

[Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
[Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

Про особенности CMD и ENTRYPOINT можно почитать [тут](https://habr.com/ru/company/southbridge/blog/329138/)
