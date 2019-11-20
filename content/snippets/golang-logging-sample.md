---
title: "Golang ja jaettu logitus"
date: 2019-11-18
draft: false
tags:
    - golang
    - programming
---

Esimerkki sovelluskontekstissa jaetun Golang-loggeri(e)n luomiseen 
 
```go
import (
	"os"
	"log"
  // ...
)

type appCtx struct {
	errorLogger *log.Logger
	infoLogger  *log.Logger
  // ...
}

func main() {
	infoLogger := log.New(os.Stdout, "[INFO]\t", log.Ldate|log.Ltime)
	errorLogger := log.New(os.Stderr, "[ERROR]\t", 
log.Ldate|log.Ltime|log.Lshortfile)

	app := &appCtx{
		errorLogger: errorLogger,
		infoLogger:  infoLogger,
		// ...
	}	
  
  	// jos ajelee vaikka serveriä niin voi tehdä
  
	s := &http.Server{
		Addr:     // ...
		ErrorLog: errorLogger,
		Handler:  // ...
	}
}
```
