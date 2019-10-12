#include "mainwindow.h"
#include "./ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

#include <iostream>

#include <bsoncxx/builder/stream/document.hpp>
#include <bsoncxx/json.hpp>

#include <mongocxx/client.hpp>
#include <mongocxx/instance.hpp>


static mongocxx::instance inst{};

void MainWindow::on_pushButton_clicked()
{
    try {
        mongocxx::uri server("mongodb://192.168.26.110:27017");

        mongocxx::client conn(server);
        bsoncxx::builder::stream::document document;

        auto collection = conn["testdb"]["testcollection"];
        document << "hello" << "world";

        collection.insert_one(document.view());
        auto cursor = collection.find({});

        for (auto&& doc : cursor) {
            std::cout << bsoncxx::to_json(doc) << std::endl;
        }
    } catch (... ) {
        std::cout << "Failed to connect to server" << std::endl;
    }

}
