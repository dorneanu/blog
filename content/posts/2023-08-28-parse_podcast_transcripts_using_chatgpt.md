+++
title = "Parse podcast transcripts using ChatGPT"
author = ["Victor Dorneanu"]
lastmod = 2023-08-28T20:55:37+02:00
tags = ["podcast", "chatgpt"]
draft = false
+++

I regularly listen to the podcast [Lage der Nation](https://lagedernation.org/) which offers _transcripts_ to
premium subscribers on their website _plus.ladernation.org._ To export quotes from
a recent episode and add them to [my private knowledge database](https://brainfck.org), I followed these
steps:

1.  I activated the developer console in my browser.
2.  In the network tab of the console, I saw a `GET` request to a URL like
    `https://plus.lagedernation.org/<...>/?podlove_transcript=json`, which fetches
    the JSON version of the transcripts (provided by [podlove](https://podlove.org/)).

Here's an excerpt:

```json
[
  {
    "start": "00:00:04.500",
    "start_ms": 4500,
    "end": "00:00:06.569",
    "end_ms": 6569,
    "speaker": "2",
    "voice": "Philip",
    "text": "weiteren Sommerfolge mit einem"
  },
  {
    "start": "00:00:06.570",
    "start_ms": 6570,
    "end": "00:00:08.849",
    "end_ms": 8849,
    "speaker": "2",
    "voice": "Philip",
    "text": "weiteren ausführlichen Interview."
  },
  [...]
  {
    "start": "00:13:41.850",
    "start_ms": 821850,
    "end": "00:13:43.949",
    "end_ms": 823949,
    "speaker": "152",
    "voice": "Jochem Marotzke",
    "text": "Ich glaube, da hilft ein"
  },
  [...]
]
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Podcast transcripts in JSON format
</div>

My desired output:

```text
Philipp:
[text]

Jochem Marotzke:
[text]
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  Desired output
</div>

I this post I'd like to illustrate how you can leverage generative AI for
solving this problem. For the following prompts I'll be using [chatgpt-shell](https://github.com/xenodium/chatgpt-shell) (an API client for OpenAPI to be used within Emacs).

```shell
ChatGPT(3.5t/Programming)> I would like to write a simple
Golang tool which will parse following JSON
[
  {
    "start": "00:00:04.500",
    "start_ms": 4500,
    "end": "00:00:06.569",
    "end_ms": 6569,
    "speaker": "2",
    "voice": "Philip",
    "text": "weiteren Sommerfolge mit einem"
  },
  {
    "start": "00:00:06.570",
    "start_ms": 6570,
    "end": "00:00:08.849",
    "end_ms": 8849,
    "speaker": "2",
    "voice": "Philip",
    "text": "weiteren ausführlichen Interview."
  },
]

First I want to print out the voice attribute and then the text one. Unless the
voice attribute doesn't change I want the text of the voice attribute to be
printed without newlines. In case the voice attribute changes I want to a double
newline to be printed out and then print again the voice attribute.
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  ChatGPT prompt
</div>

And now the response:

````markdown
You can achieve what you described by parsing the JSON data and then iterating
over the array of objects. For each object, you can keep track of the previous
voice attribute and compare it with the current one to determine if a newline
should be printed.

Here's a simple example code snippet to get you started:

```go
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
)

type Item struct {
	Start    string `json:"start"`
	StartMs  int    `json:"start_ms"`
	End      string `json:"end"`
	EndMs    int    `json:"end_ms"`
	Speaker  string `json:"speaker"`
	Voice    string `json:"voice"`
	Text     string `json:"text"`
}

func main() {
	// Read the JSON data from a file or any other source
	data, err := ioutil.ReadFile("data.json")
	if err != nil {
		fmt.Println("Error reading JSON file:", err)
		return
	}

	var items []Item
	err = json.Unmarshal(data, &items)
	if err != nil {
		fmt.Println("Error parsing JSON:", err)
		return
	}

	prevVoice := ""
	for _, item := range items {
		if item.Voice != prevVoice {
			// Print a double newline if the voice attribute changes
			fmt.Println("\n\n", item.Voice)
			prevVoice = item.Voice
		} else {
			// Print the text attribute without a newline
			fmt.Print(" ")
		}
		fmt.Print(item.Text)
	}

	fmt.Println() // Print a newline at the end
}
```

Make sure to replace `"data.json"` with the path to your JSON file. The code
reads the JSON file, parses it into a slice of `Item` structs, and then iterates
over the items while printing the voice and text attributes according to your
requirements.

````
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3:</span>
  ChatGPT response
</div>

I wasn't quite happy about the fact I had to use `data.json` as an input to the program, so I asked ChatGPT to adapt a little bit:

````shell
ChatGPT(3.5t/Programming)> Change the program so that it accepts a CLI argument to specify the file.
````
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4:</span>
  ChatGPT prompt
</div>

And voila:

````markdown
To modify the program to accept a command-line argument for the JSON file, you
can use the `os` package in Go. Here's an updated version of the code that
incorporates this change:

```go
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

type Item struct {
	Start   string `json:"start"`
	StartMs int    `json:"start_ms"`
	End     string `json:"end"`
	EndMs   int    `json:"end_ms"`
	Speaker string `json:"speaker"`
	Voice   string `json:"voice"`
	Text    string `json:"text"`
}

func main() {
	// Check if the file path is provided as a command-line argument
	if len(os.Args) < 2 {
		fmt.Println("Please provide the JSON file path as a command-line argument.")
		return
	}

	filePath := os.Args[1]

	// Read the JSON file
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Println("Error reading JSON file:", err)
		return
	}

	var items []Item
	err = json.Unmarshal(data, &items)
	if err != nil {
		fmt.Println("Error parsing JSON:", err)
		return
	}

	prevVoice := ""
	for _, item := range items {
		if item.Voice != prevVoice {
			// Print a double newline if the voice attribute changes
			fmt.Println("\n\n", item.Voice)
			prevVoice = item.Voice
		} else {
			// Print the text attribute without a newline
			fmt.Print(" ")
		}
		fmt.Print(item.Text)
	}

	fmt.Println() // Print a newline at the end
}
```

Now you can run the program with the JSON file path as a command-line argument
like this:

```shell
go run main.go data.json
```

Replace `main.go` with the name of your Go source file, and `data.json` with the
actual path to your JSON file.

````
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5:</span>
  ChatGPT response
</div>

I've copied the Go code, put into main.go and ran it:

````shell
go run main.go
````

````text
Please provide the JSON file path as a command-line argument.
````

Ok, next try:

````shell
go run main.go transcript.json | head -n 30
````

````text
 Philip
Ganz herzlich willkommen zur Lage der Nation mit einer weiteren Sommerfolge mit einem weiteren ausführlichen Interview. Mein Name ist Philip Banse.

 Ulf
Und ich bin Ulf Buermeyer. Der Philip ist Journalist. Ich bin Jurist aus Berlin. Schön, dass ihr wieder dabei seid bei unserem Podcast.

 Philip
Bevor es losgeht, bevor wir einsteigen in das heutige Interview, noch der Hinweis: Es gibt ja mal wieder eine Lage live. Hatten wir lange nicht mehr.

 Ulf
Mal wieder ist gut, Philip. Endlich mal wieder, würde ich sagen, denn wir haben ja jetzt eine ganze Weile Pause gemacht. Aber im Oktober sind wir wieder live zu sehen, und zwar genau genommen am 19. Oktober in Frankfurt am Main, am Rande der Frankfurter Buchmesse. Ganz wichtig: Ihr braucht keine Tickets für die Buchmesse, aber ihr braucht natürlich ein Ticket für die Lage live. Wenn ihr uns mal auf der Bühne dabei erleben wollt, wie wir die Lage der Nation aufnehmen, wie wir unser Buch vorstellen, aber auch, wie wir eure Fragen aus dem Publikum beantworten.

 Philip
Genau. Und hinterher gibt es da noch, wenn ihr wollt, ein gemeinsames Kaltgetränk und wir können uns ein bisschen unterhalten. Die Tickets für die Lage live gibt es unter Lage.Live, einfach im Browser eintippen, Lage.Live und ihr landet bei uns im Ticket Shop. Wir sind für das heutige Interview mal wieder in den Zug gestiegen. Es war eine mittelprächtige Erfahrung, muss ich ehrlich sagen. Aber wir sind noch rechtzeitig angekommen.

 Ulf
Als der Zug fuhr, war es schön. Es hat nur ein bisschen gedauert. 45 Minuten Verzögerung.

 Philip
Das war alles eingeplant.

 Ulf
Aber jetzt sind wir ja da. Und jetzt sitzen wir zusammen mit Professor Dr. Jochem Marotzke. Er arbeitet am Max Planck Institut für Meteorologie, ist genau genommen sogar der Direktor dieses MPI und einer der renommiertesten Klimaforscher in Deutschland. Und wahrscheinlich sogar international. Denn er ist unter anderem einer der Mitautoren, Autorinnen des jüngsten IPCC Berichts. Wer die Lage schon länger hörte, hat davon bestimmt schon mal gehört. Das ist so eine Art Metastudie, wo quasi der Stand der wissenschaftlichen Erkenntnis zum Thema Klimawandel zusammengefasst wird. Ganz herzlich willkommen in der Lage der Nation Professor Marotzke.

 Jochen Marotzke
Ja, vielen Dank für die Einladung.

 Philip
````

I hope this might be useful to someone 🙂
