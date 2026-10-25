workspace "shelf" "The approved target architecture: the desired state every PR is checked against." {
  model {
    librarian = person "Librarian" "Office staff who add books to the shelf, borrow and return them, and chase overdue loans." {
      properties {
        "bearing.requirements" "#1,#2,#3,#4,#5"
      }
    }

    shelf = softwareSystem "Shelf" "Office book-lending service: keeps the catalogue of books and the loans against them." {
      properties {
        "bearing.requirements" "#1,#2,#3,#4,#5"
      }

      shelfApi = container "Shelf API" "Serves the book-lending HTTP API." "Node.js, TypeScript" {
        properties {
          "bearing.requirements" "#1,#2,#3,#4,#5"
        }

        httpApi = component "HTTP API" {
          description "Starts the server, routes requests, validates input and maps domain outcomes to HTTP responses"
          technology "TypeScript"
          properties {
            "bearing.path" "src/shelf-api/http"
            "bearing.requirements" "#1,#2,#3,#4,#5"
          }
        }

        catalog = component "Catalog" {
          description "Adds books, rejects duplicate ISBNs and searches books by title with their availability"
          technology "TypeScript"
          properties {
            "bearing.path" "src/shelf-api/catalog"
            "bearing.requirements" "#1,#5"
          }
        }

        lending = component "Lending" {
          description "Opens and closes loans, sets due dates in local time and finds overdue loans"
          technology "TypeScript"
          properties {
            "bearing.path" "src/shelf-api/lending"
            "bearing.requirements" "#2,#3,#4"
          }
        }
      }

      database = container "Database" "Stores books and loans." "PostgreSQL" {
        tags "Database"
        properties {
          "bearing.requirements" "#1,#2,#3,#4,#5"
        }
      }
    }

    librarian -> httpApi "Adds, searches, borrows and returns books, and lists overdue loans using" "JSON/HTTPS" {
      properties {
        "bearing.requirements" "#1,#2,#3,#4,#5"
      }
    }
    httpApi -> catalog "Adds and searches books using" {
      properties {
        "bearing.requirements" "#1,#5"
      }
    }
    httpApi -> lending "Borrows and returns books and lists overdue loans using" {
      properties {
        "bearing.requirements" "#2,#3,#4"
      }
    }
    catalog -> database "Reads and writes books, and reads open loans for availability, in" "SQL/TCP" {
      properties {
        "bearing.requirements" "#1,#5"
      }
    }
    lending -> database "Reads and writes loans in" "SQL/TCP" {
      properties {
        "bearing.requirements" "#2,#3,#4"
      }
    }

    production = deploymentEnvironment "Production" {
      host = deploymentNode "Docker host" "A single office server running the stack with Docker Compose." "Docker Compose" {
        apiNode = deploymentNode "shelf-api" "" "Docker container, node:22" {
          containerInstance shelfApi
        }
        dbNode = deploymentNode "postgres" "" "Docker container, postgres:17" {
          containerInstance database
        }
      }
    }
  }

  views {
    systemContext shelf "context" {
      include *
      autoLayout
    }

    container shelf "containers" {
      include *
      autoLayout
    }

    component shelfApi "components" {
      include *
      autoLayout
    }

    dynamic shelfApi "req-1" "#1 Add a book" {
      librarian -> httpApi "POST /books {title, isbn}"
      httpApi -> catalog "addBook()"
      catalog -> database "INSERT INTO books"
      autoLayout
    }

    dynamic shelfApi "req-2" "#2 Borrow a book" {
      librarian -> httpApi "POST /books/{isbn}/borrow {borrower}"
      httpApi -> lending "borrow()"
      lending -> database "INSERT INTO loans"
      autoLayout
    }

    dynamic shelfApi "req-3" "#3 Return a book" {
      librarian -> httpApi "POST /books/{isbn}/return"
      httpApi -> lending "returnBook()"
      lending -> database "UPDATE loans SET returned_at"
      autoLayout
    }

    dynamic shelfApi "req-4" "#4 List overdue loans" {
      librarian -> httpApi "GET /loans/overdue"
      httpApi -> lending "listOverdue()"
      lending -> database "SELECT open loans due before today"
      autoLayout
    }

    dynamic shelfApi "req-5" "#5 Search by title" {
      librarian -> httpApi "GET /books?title={text}"
      httpApi -> catalog "searchByTitle()"
      catalog -> database "SELECT books with open-loan status"
      autoLayout
    }

    deployment shelf production "deployment" {
      include *
      autoLayout
    }

    styles {
      element "Database" {
        shape Cylinder
      }
      element "Person" {
        shape Person
      }
    }
  }
}
