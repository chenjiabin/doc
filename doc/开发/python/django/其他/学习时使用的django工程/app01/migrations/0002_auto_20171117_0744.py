# -*- coding: utf-8 -*-
# Generated by Django 1.11.6 on 2017-11-17 07:44
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app01', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Apps',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=50)),
                ('path', models.CharField(max_length=200)),
            ],
        ),
        migrations.CreateModel(
            name='Hosts',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('hostname', models.CharField(max_length=50)),
                ('ip', models.CharField(max_length=200)),
                ('memory', models.IntegerField()),
            ],
        ),
        migrations.AddField(
            model_name='apps',
            name='table',
            field=models.ManyToManyField(to='app01.Hosts'),
        ),
    ]
