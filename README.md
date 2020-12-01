**Контейнер** - один или несколько linux-процессов, запущенных в изолированном окружении. Это значит, 
что некоторые части операционной системы с точки зрения этих запущенных процессов воспринимаются особенным образом, 
таким образом, который контролируется системой контейнеризации, а не самой операционной системой.

**Docker image** - правила, по которым будут создаваться контейнеры с помощью
данного образа.

**Docker container** - инстанс docker image.

### Работа с файлами в контейнерах Docker

Файловая система контейнера состоит из большого кол-ва слоев, 
при этом слой контейнера доступен как для чтения так и для записи, 
а слой образа доступен только для чтения. 

Что происходит при попытке чтения файла из слоя образа: 
* Union File System ищет данный файл, начиная со слоя контейнера и далее в слоях образа

Что происходит при попытке записи в файл из слоя образа: 
* Так как файлы из слоя образа являются неизменяемыми 
то мы не можем напрямую писать в файл слоя образа
* Copy-on-write: создается копия файла или части файла, 
которая размещается в слое контейнера и в нее вносятся изменения
* При удалении файла создается специальный файл, который указывает на то, что файл удален
и Union File System не показывает удаленный файл пользователю 

При такой реализации доступа к файлам чтение и запись замедляются. 
Насколько медленными будут эти процессы, зависит от конкретной реализации Union File System

Рекомендация: не хранить персистентные (требующие более долго хранения) данные
в слое контейнера

Контейнер может взаимодействовать с файловой системой хоста 
как на чтение так и на запись. Для монтирования файлов с хоста внутрь контейнера
используется команда: 

```shell script
docker run -v {путь в файловой системе хоста}:{путь внутри контейнера}:{права доступа}
```

Для хранения персистентных данных используются Data Volume Container. Пример:

```shell script
docker create -v /srv --name store ubuntu:14.04 /bin/true
docker run -it --rm --volumes-from store ubuntu:14.04
```
