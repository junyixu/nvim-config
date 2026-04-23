#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2023 Junyi Xu <jyxu@mail.ustc.edu.cn>
#
# Distributed under terms of the MIT license.
"""
Vim Diary Navigation Plugin
"""

import datetime
import os
import vim
from pathlib import Path


class DiaryNavigator:

    def __init__(self):
        self.diary_dir = vim.eval('g:diary_dir')
        self.max_search_days = int(vim.eval('g:diary_max_search_days'))

    def _get_current_date(self):
        buffer_name = vim.current.buffer.name
        if buffer_name:
            return datetime.date.fromisoformat(Path(buffer_name).stem)
        return datetime.date.today()

    def _find_diary_entry(self, start_date, direction):
        delta = datetime.timedelta(days=direction)
        current_date = start_date

        for i in range(self.max_search_days):
            current_date += delta
            diary_filename = f"{current_date.isoformat()}.md"
            diary_path = os.path.join(self.diary_dir, diary_filename)

            if os.path.exists(diary_path):
                return diary_path
        return None

    def navigate_diary(self, direction):
        current_date = self._get_current_date()  # according to current buffer
        diary_path = self._find_diary_entry(current_date, direction)

        if diary_path:
            vim.command(f'silent edit {diary_path}')


# 全局实例和函数
diary_navigator = DiaryNavigator()


def last_diary():
    diary_navigator.navigate_diary(-1)


def next_diary():
    diary_navigator.navigate_diary(1)
