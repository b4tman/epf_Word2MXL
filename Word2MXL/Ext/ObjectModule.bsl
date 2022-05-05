﻿Функция ВывестиДокументВордВМоксель(ИмяФайла, рСантиметр = 6.25, рШиринаСтраницы = 75) Экспорт
	// источник: https://infostart.ru/1c/articles/1499795/
	комВорд = Неопределено;
	комДокумент = Неопределено;
	Попытка
		// Для пересчётов использовать комВорд.CentimetersToPoints(ЧислоСМ) и комВорд.PointsToCentimeters(ЧислоПунктов)
		//рСантиметр=6.25; // в средних символах шрифта (при необходимости пересчитывать по рДиапазон.CharacterWidth - ширина символов, константа WdCharacterWidth
		//рШиринаСтраницы=75; // эмпирически, довести до ума с учётом //сообщить("стран ширина "+стран.PageWidth+", высота "+стран.PageHeight); // в пунктах, работает
		
		// Типовые настройки документа Ворд:
		// 1.25 до номера (отступ первой строки) и 1.89 табуляция (до основного текста)
		// Размеры листа А4 в сантиметрах: 21х29.7
		
		комВорд = Новый COMОбъект("Word.Application");
		рПодтверждатьПреобразования = Истина;
		рТолькоЧтение = Истина;
		комДокумент = комВорд.Documents.Open(ИмяФайла, рПодтверждатьПреобразования, рТолькоЧтение);
		
		#Область Проверки
		комСтраница = комДокумент.PageSetup;
		Если комСтраница.TextColumns.Count > 1 Тогда
			Сообщить("Текущая версия не обрабатывает многоколонные документы!");
			ЗакрытьДокумент(комДокумент); // без сохранения
			ЗакрытьВорд(комВорд);
			Возврат Неопределено;
		КонецЕсли;
		рШиринаСтраницыВорда = Окр(комВорд.PointsToCentimeters(комСтраница.PageWidth), 2);
		рВысотаСтраницыВорда = Окр(комВорд.PointsToCentimeters(комСтраница.PageHeight), 2);
		Если НЕ ((20 <= рШиринаСтраницыВорда и рШиринаСтраницыВорда <= 22) и (28 <= рВысотаСтраницыВорда и рВысотаСтраницыВорда <= 30)) Тогда
			Сообщить("Текущая версия не обрабатывает размеры страницы, отличающиеся от А4!");
			ЗакрытьДокумент(комДокумент); // без сохранения
			ЗакрытьВорд(комВорд);
			Возврат Неопределено;
		КонецЕсли;
		#КонецОбласти
		
		// подготовка вывода таблиц
		мКомТаблиц = Новый Массив;
		Для каждого комТаблица Из комДокумент.Tables Цикл
			мКомТаблиц.Добавить(Новый Структура("Начало,Конец,Таблица", комТаблица.Range.Start, комТаблица.Range.End, комТаблица));
		КонецЦикла;
		
		#Область ПодготовкаВыводаНумерованныхСписков
		// можно, конечно, рСписок.ConvertNumbersToText(ТипНомера) - но это не лучший выход, и это изменение документа
		//
		соотПараграфовСписков = Новый Соответствие;
		Для каждого рСписок Из комДокумент.Lists Цикл // свойство комДокумент.Lists.Count ситуационно-зависимое, не применять!
			// рЛист.CountNumberedItems();
			Для каждого рПараграфСписка Из рСписок.ListParagraphs Цикл
				рФорматСписка = рПараграфСписка.Range.ListFormat;
				рТипСписка = рФорматСписка.ListType; // WdListType
				Если рТипСписка = 0 или рТипСписка = 2 или рТипСписка = 6 Тогда
					// ненумерованные и bullet игнорируем
				Иначе
					// заниматься иерархией с проверкой погружения (рФорматСписка.ListLevelNumber) не будем, нам достаточно проверить так:
					рПредставлениеПункта = СокрЛП(рФорматСписка.ListString);
					// выравнивание смотрим по первой позиции уровней (хотя можно перебирать, смотреть по позиции или по NumberFormat)
					Попытка рВыравнивание = рФорматСписка.ListTemplate.ListLevels.Item(0).Alignment Исключение рВыравнивание = 0 КонецПопытки;
					// из первого уровня также можно брать NumberPosition - отступ,если будет надо; он в пунктах, поэтому тоже может потребоваться пересчёт!
					Если СтрРазделить(рПредставлениеПункта, ".", Ложь).Найти(рФорматСписка.ListValue) = 0 Тогда
						Сообщить("Внимание! Нарушение нумерации списка для " + рПредставлениеПункта + "!");
					КонецЕсли;
					// фиксируем для дальнейшего вывода
					соотПараграфовСписков.Вставить(рПараграфСписка.Range.Start, Новый Структура("Номер,Выравнивание", рПредставлениеПункта, рВыравнивание));
				КонецЕсли;
			КонецЦикла;
		КонецЦикла;
		#КонецОбласти
		
		// FitTextWidth для диапазонов НЕ используем, в т.ч. для комДокумент.Range()
		
		т = Новый ТабличныйДокумент;
		
		#Область ПодготовкаТабДокумента
		// устанавливаем ширины рабочих колонок А4
		стлб = 1;
		Пока Истина Цикл
			т.Область(1, стлб, 1, стлб).ШиринаКолонки = Окр(рСантиметр / 4, 2);
			стлб = стлб + 1;
			Если т.ШиринаТаблицы > рШиринаСтраницы Тогда
				Прервать;
			КонецЕсли;
		КонецЦикла;
		#КонецОбласти
		
		#Область ВыводОсновныхДанных
		стрк = 1;
		рПравыйКрайнийСтолбец = т.ШиринаТаблицы;
		рИдётТаблица = Ложь;
		
		Для каждого рПараграф Из комДокумент.Paragraphs Цикл
			// к сожалению, рПараграф.ListNumberOriginal использовать ненадёнжно
			рДиапазон = рПараграф.Range;
			
			рТекстДиапазона = рДиапазон.Text;
			рНачалоДиапазона = рДиапазон.Start;
			рКонецДиапазона = рДиапазон.End;
			
			#Область ВыводПозицииНумерованногоСписка
			// использовать рДиапазон.ListFormat.ListLevelNumber и рДиапазон.ListFormat.ListValue не рекомендуется
			рПараграфСписка = соотПараграфовСписков.Получить(рНачалоДиапазона);
			Если рПараграфСписка = Неопределено Тогда
				рПредставлениеПункта = "";
				рВыравнивание = 0;
			Иначе
				рПредставлениеПункта = СокрЛП(рПараграфСписка.Номер);
				рВыравнивание = рПараграфСписка.Выравнивание;
			КонецЕсли;
			Если ПустаяСтрока(рПредставлениеПункта) Тогда
				// нумерации списка нет
				рГраницаОбластиПараграфа = 1;
			Иначе // надо выводить № пункта списка
				рОбластьНомера = т.Область(стрк, 1, стрк, 4);
				рОбластьНомера.Объединить();
				рОбластьНомера.Текст = рПредставлениеПункта;
				рОбластьНомера.Шрифт = ПостроитьШрифт(ВыборШрифта(рДиапазон)); // или рДиапазон.ListStyle.Font, если они разные
				рОбластьНомера.ГоризонтальноеПоложение = ПолучитьВыравнивание(рВыравнивание);
				рОбластьНомера.ВертикальноеПоложение = ВертикальноеПоложение.Верх; // по умолчанию
				рГраницаОбластиПараграфа = 5;
			КонецЕсли;
			#КонецОбласти
			
			комТаблица = Неопределено;
			Для каждого знч Из мКомТаблиц Цикл
				Если знч.Начало <= рНачалоДиапазона и рНачалоДиапазона <= знч.Конец
					и знч.Начало <= рКонецДиапазона и рКонецДиапазона <= знч.Конец
					Тогда // можно было бы рДиапазон.InRange(комТаблица.Range), но оно медленнее
					комТаблица = знч.Таблица; Прервать;
				КонецЕсли;
			КонецЦикла;
			
			Если комТаблица = Неопределено Тогда
				рИдётТаблица = Ложь;
				
				#Область ВыводОбычногоАбзаца
				// для параграфа и Диапазон.ParagraphFormat, при необходимости:
				// рПараграф.FirstLineIndent - Возвращает или устанавливает значение в пунктах для первой линии или отступа.
				// рПараграф.LeftIndent - Отступ слева в пунктах.
				// рПараграф.RightIndent - Отступ справа в пунктах.
				// рПараграф.LineSpacing - Междустрочный интервал.
				// рПараграф.PageSetup.PageWidth аналогично ширине документа в целом, можно не заморачиваться
				
				рОбластьПараграфа = т.Область(стрк, рГраницаОбластиПараграфа, стрк, рПравыйКрайнийСтолбец);
				рОбластьПараграфа.Объединить();
				рОбластьПараграфа.Текст = рТекстДиапазона;
				рОбластьПараграфа.Шрифт = ПостроитьШрифт(ВыборШрифта(рДиапазон)); // а не рПараграф.Style.Font!
				рОбластьПараграфа.ГоризонтальноеПоложение = ПолучитьВыравнивание(рПараграф.Alignment); // или лучше рДиапазон.ParagraphFormat.Alignment?
				рОбластьПараграфа.ВертикальноеПоложение = ВертикальноеПоложение.Верх; // по умолчанию
				рОбластьПараграфа.РазмещениеТекста = ТипРазмещенияТекстаТабличногоДокумента.Переносить; // по умолчанию
				#КонецОбласти
				
				стрк = стрк + 1;
			Иначе
				Если не рИдётТаблица Тогда // выводим таблицу, а далее пропускаем все входящие в неё диапазоны, и идём до её конца
					ВывестиТаблицу(комВорд, комТаблица, т, стрк, рСантиметр);
				КонецЕсли;
				рИдётТаблица = Истина;
				Продолжить; // стрк уже "промотана" до нужной позиции пост-таблицы
			КонецЕсли;
			
		КонецЦикла;
		
		#КонецОбласти
		
		ЗакрытьДокумент(комДокумент); // без сохранения
		ЗакрытьВорд(комВорд);
        
        ИсправитьНедопустимыеСимволы(т);
		Возврат т;
		
	Исключение
		Ошибка = ОписаниеОшибки();
		Причина = ИнформацияОбОшибке();
		
		ЗакрытьДокумент(комДокумент);
		ЗакрытьВорд(комВорд);
		
		ВызватьИсключение("Ошибка конвертации в mxl", КатегорияОшибки.ОшибкаВнешнегоИсточникаДанных, "500", Ошибка, Причина);
	КонецПопытки;
	
	Возврат Неопределено;
КонецФункции

Функция ПостроитьШрифт(комШрифт)
	Возврат Новый Шрифт(
		комШрифт.Name,
		комШрифт.Size,
		комШрифт.Bold,
		комШрифт.Italic,
		комШрифт.Underline,
		комШрифт.StrikeThrough,
		комШрифт.Scaling
	);
КонецФункции

Функция ВыборШрифта(рДиапазон)
	Результат = рДиапазон.Font;
	Если Результат.Size > 9999 Тогда
		Результат = рДиапазон.ListStyle.Font;
	КонецЕсли;
	
	Возврат Результат;
КонецФункции


Функция ПостроитьРамкуЯчейки(комРамка, чисОтступ)
	Если комРамка.Visible Тогда
		чисСтиль = комРамка.LineStyle;
		рТолщина = 1;
		Если чисСтиль = 1 Тогда
			рТипЛинии = ТипЛинииЯчейкиТабличногоДокумента.Сплошная;
			// если надо, толщину можно сделать подробнее по комРамка.LineWidth
		ИначеЕсли чисСтиль = 2 Тогда
			рТипЛинии = ТипЛинииЯчейкиТабличногоДокумента.Точечная;
		ИначеЕсли чисСтиль = 5 Тогда
			рТипЛинии = ТипЛинииЯчейкиТабличногоДокумента.РедкийПунктир;
		ИначеЕсли чисСтиль = 6 Тогда
			рТипЛинии = ТипЛинииЯчейкиТабличногоДокумента.ЧастыйПунктир;
		ИначеЕсли чисСтиль = 7 Тогда
			рТипЛинии = ТипЛинииЯчейкиТабличногоДокумента.Двойная;
		Иначе
			рТипЛинии = ТипЛинииЯчейкиТабличногоДокумента.БольшойПунктир;
		КонецЕсли;
		рОтступ = (чисОтступ > 0); // пока так
		Возврат Новый Линия(рТипЛинии, рТолщина, рОтступ);
	Иначе
		Возврат Новый Линия(ТипЛинииЯчейкиТабличногоДокумента.НетЛинии);
	КонецЕсли;
КонецФункции


Функция ПолучитьВыравнивание(чисВыравнивание)
	// wdListLevelAlignCenter - 1 – По центру wdListLevelAlignLeft - 0 – По левому краю wdListLevelAlignRight - 2 – По правому краю
	Если чисВыравнивание = 1 Тогда
		Возврат ГоризонтальноеПоложение.Центр;
	ИначеЕсли чисВыравнивание = 2 Тогда
		Возврат ГоризонтальноеПоложение.Право;
	ИначеЕсли чисВыравнивание = 3 Тогда
		Возврат ГоризонтальноеПоложение.ПоШирине;
	Иначе
		Возврат ГоризонтальноеПоложение.Лево;
	КонецЕсли;
КонецФункции


Процедура ВывестиТаблицу(комВорд, комТаблица, табДокумент, текСтрока, рСантиметр = 6.25)
	//рСантиметр=6.25;
	рСимвол7 = Символ(7);
	
	квоСтрок = комТаблица.Rows.Count;
	квоКолонок = комТаблица.Columns.Count;
	
	Для стркДок = 1 По квоСтрок Цикл
		стлб = 1;
		
		Для стлбДок = 1 По квоКолонок Цикл
			Попытка
				комЯчейка = комТаблица.Cell(стркДок, стлбДок);
			Исключение
				Продолжить;
			КонецПопытки;
			
			квоЯчеекМхл = Окр(комВорд.PointsToCentimeters(комЯчейка.Width * 4), 0, РежимОкругления.Окр15как20); // 1 см. это 4 ячейки мхл
			рОбластьЯчейки = табДокумент.Область(текСтрока, стлб, текСтрока, стлб + квоЯчеекМхл - 1);
			рОбластьЯчейки.Объединить();
			
			Если комЯчейка.FitText или комЯчейка.WordWrap Тогда // пока так
				рОбластьЯчейки.РазмещениеТекста = ТипРазмещенияТекстаТабличногоДокумента.Переносить;
			Иначе
				рОбластьЯчейки.РазмещениеТекста = ТипРазмещенияТекстаТабличногоДокумента.Авто;
			КонецЕсли;
			
			рДиапазонЯчейки = комЯчейка.Range;
			//
			рТекстДиапазонаЯчейки = СокрЛП(рДиапазонЯчейки.Text);
			Если Прав(рТекстДиапазонаЯчейки, 1) = рСимвол7 Тогда
				рТекстДиапазонаЯчейки = Лев(рТекстДиапазонаЯчейки, СтрДлина(рТекстДиапазонаЯчейки) - 1);
			КонецЕсли;
			рОбластьЯчейки.Текст = рТекстДиапазонаЯчейки;
			//
			рОбластьЯчейки.Шрифт = ПостроитьШрифт(ВыборШрифта(рДиапазонЯчейки));
			
			// на практике удобнее оставлять автовысоту, но иногда может понадобиться:
			//рОбластьЯчейки.АвтоВысотаСтроки=Ложь;
			//рОбластьЯчейки.ВысотаСтроки=рСантиметр*Окр(комВорд.PointsToCentimeters(комЯчейка.Height),0,РежимОкругления.Окр15как20);
			
			рОбластьЯчейки.ГоризонтальноеПоложение = ПолучитьВыравнивание(рДиапазонЯчейки.ParagraphFormat.Alignment);
			// отступ - в пунктах, при необходимости требуется пересчёт!
			//Если рОбластьЯчейки.ГоризонтальноеПоложение=ГоризонтальноеПоложение.Лево Тогда
			//	рОбластьЯчейки.Отступ=комЯчейка.LeftPadding;
			//ИначеЕсли рОбластьЯчейки.ГоризонтальноеПоложение=ГоризонтальноеПоложение.Право Тогда
			//	рОбластьЯчейки.Отступ=комЯчейка.RightPadding;
			//КонецЕсли;
			
			вертВыравнивание = комЯчейка.VerticalAlignment;
			Если вертВыравнивание = 1 Тогда
				рОбластьЯчейки.ВертикальноеПоложение = ВертикальноеПоложение.Центр;
			ИначеЕсли вертВыравнивание = 3 Тогда
				рОбластьЯчейки.ВертикальноеПоложение = ВертикальноеПоложение.Низ;
			Иначе
				рОбластьЯчейки.ВертикальноеПоложение = ВертикальноеПоложение.Верх;
			КонецЕсли;
			
			рОбластьЯчейки.ГраницаСверху = ПостроитьРамкуЯчейки(комЯчейка.Borders(-1), комЯчейка.Borders.DistanceFromTop);
			рОбластьЯчейки.ГраницаСлева = ПостроитьРамкуЯчейки(комЯчейка.Borders(-2), комЯчейка.Borders.DistanceFromLeft);
			рОбластьЯчейки.ГраницаСнизу = ПостроитьРамкуЯчейки(комЯчейка.Borders(-3), комЯчейка.Borders.DistanceFromBottom);
			рОбластьЯчейки.ГраницаСправа = ПостроитьРамкуЯчейки(комЯчейка.Borders(-4), комЯчейка.Borders.DistanceFromRight);
			
			стлб = стлб + квоЯчеекМхл;
		КонецЦикла;
		
		текСтрока = текСтрока + 1;
	КонецЦикла;
	
КонецПроцедуры

Процедура ЗакрытьДокумент(комДокумент)
	Если Неопределено = комДокумент Тогда
		Возврат;
	КонецЕсли;
	
	Попытка
		комДокумент.Close(Ложь);
	Исключение
		;
	КонецПопытки;
	комДокумент = Неопределено;
КонецПроцедуры

Процедура ЗакрытьВорд(комВорд)
	Если Неопределено = комВорд Тогда
		Возврат;
	КонецЕсли;
	
	Попытка
		комВорд.Quit(0);
	Исключение
		;
	КонецПопытки;
	комВорд = Неопределено;
КонецПроцедуры

//Строки = СтрРазделить("0,1,2,3,4,5,6,7,8,9", ",");
//Числа  = Мап("Результат = Число(Элемент) * _.Множитель", Строки, Новый Структура("Множитель", 2));
//Часть  = Фильтр("Условие = Элемент > 4 * _.Множитель", Числа, Новый Структура("Множитель", 2));
//Сообщить(СтрСоединить(Часть, ","));
Функция ВыполнитьФрагмент(Знач Код, Вход, ИмяВход = "Вход", ИмяВыход = "Выход", Инициализировать = Ложь, _ = Неопределено)
	Выход = ?(Инициализировать, Вход, Неопределено);
	
	Если НЕ "Вход" = ИмяВход Тогда
		Код = СтрШаблон("%1=Вход;%2", ИмяВход, Код);
	КонецЕсли;
	Если НЕ "Выход" = ИмяВыход Тогда
		Код = СтрШаблон("%1;Выход=%2", Код, ИмяВыход);
	КонецЕсли;
	
	Выполнить(Код);
	
	Возврат Выход;
КонецФункции
Функция Мап(Код, Коллекция, _ = Неопределено)
	Результат = Новый Массив;
	
	Для Каждого Элемент Из Коллекция Цикл
		ЭлементКопия = Элемент;
		ЭлементКопия = ОбщегоНазначения.СкопироватьРекурсивно(ЭлементКопия);
		ЭлементКопия = ВыполнитьФрагмент(Код, ЭлементКопия, "Элемент", "Результат", Истина, _);
		Результат.Добавить(ЭлементКопия);
	КонецЦикла;
	
	Возврат Результат;
КонецФункции
Функция Фильтр(КодУсловия, Коллекция, _ = Неопределено)
	Результат = Новый Массив;
	
	Для Каждого Элемент Из Коллекция Цикл
		Условие = ВыполнитьФрагмент(КодУсловия, Элемент, "Элемент", "Условие", , _);
		Если Условие Тогда
			Результат.Добавить(Элемент);
		КонецЕсли;
	КонецЦикла;
	
	Возврат Результат;
КонецФункции
Функция ВыполнитьФрагмент_ДляСвертки(Знач Код, Элемент, Знач Результат, _ = Неопределено)
	Выполнить(Код);
	Возврат Результат;
КонецФункции
Функция Свернуть(Код, Коллекция, Знач Результат = Неопределено, _ = Неопределено)
	Для Каждого Элемент Из Коллекция Цикл
		Результат = ВыполнитьФрагмент_ДляСвертки(Код, Элемент, Результат, _);
	КонецЦикла;
	
	Возврат Результат;
КонецФункции

Функция ВзятьНеБольше(Коллекция, Знач Количество)
	Результат = Новый Массив;
	Для Каждого ТекСтр Из Коллекция Цикл
		Если 1 > Количество Тогда
			Прервать;
		КонецЕсли;
		
		Результат.Добавить(ТекСтр);
		
		Количество = Количество - 1;
	КонецЦикла;
	Возврат Результат;
КонецФункции
Функция Пропустить(Коллекция, Знач Количество)
	Результат = Новый Массив;
	Сч = 0;
	Для Каждого ТекСтр Из Коллекция Цикл
		Если 0 < Количество Тогда
			Количество = Количество - 1;
			Продолжить;
		КонецЕсли;
		
		Результат.Добавить(ТекСтр);
	КонецЦикла;
	Возврат Результат;
КонецФункции

Функция АлфавитСистемСчисления(Нотация=36)
    Алфавит = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    ДлинаАлфавита = СтрДлина(Алфавит);
    Результат = "";
    Если ДлинаАлфавита = Нотация Тогда
        Результат = Алфавит;
    ИначеЕсли ДлинаАлфавита > Нотация Тогда
        Результат = Лев(Алфавит, Нотация);
    Иначе
        ВызватьИсключение "Алфавит слишком мал";
    КонецЕсли;
    
    Возврат Результат;
КонецФункции

Функция ЧислоВДругуюСистему(Знач Значение = 0, Нотация = 36)
	Если Нотация <= 0 Тогда
		Возврат "";
	КонецЕсли;
	
	Значение = Цел(Число(Значение));
    Если Значение <= 0 Тогда
        Возврат "0";
	КонецЕсли;
	
	Алфавит = АлфавитСистемСчисления(Нотация);
	Результат = "";
	Пока Значение > 0 Цикл
		Результат = Сред(Алфавит, Значение % Нотация + 1, 1) + Результат;
		Значение = Цел(Значение / Нотация);
	КонецЦикла;
	
	Возврат Результат;
КонецФункции

Функция ЧислоИзДругойСистемы(Знач Значение = "0", Нотация = 36) 
    Если Нотация <= 0 Тогда
		Возврат 0;
	КонецЕсли;
	
	Значение = СокрЛП(Значение);
	Если Значение = "0" Тогда
		Возврат 0;
	КонецЕсли;
    
    Алфавит = АлфавитСистемСчисления(Нотация);
	Результат = 0;
	Длина = СтрДлина(Значение);
	Для Позиция = 1 По Длина Цикл
		Множитель = Pow(Нотация, Длина - Позиция);
        ТекСимвол = Сред(Значение, Позиция, 1);
        ИндексСимвола = СтрНайти(Алфавит, ТекСимвол) - 1;
        Результат = Результат + ИндексСимвола * Множитель;
	КонецЦикла;
	Возврат Окр(Результат);
КонецФункции

Функция Ох(Знач Стр)
	Возврат ЧислоИзДругойСистемы(Стр, 16);
КонецФункции

Функция Hex(Знач Числ)
	Возврат ЧислоВДругуюСистему(Числ, 16);
КонецФункции

Процедура ЗаменитьТекстВТД(ТД, Текст, Замена)
    Область = ТД.НайтиТекст(Текст);
	Пока НЕ Неопределено = Область Цикл
		Область.Текст = СтрЗаменить(Область.Текст, Текст, Замена);
		Область = ТД.НайтиТекст(Текст, Область);
	КонецЦикла;
КонецПроцедуры

Процедура ИсправитьНедопустимыеСимволы(ТабДок)
    // список символов из:
    // https://ru.wikipedia.org/wiki/%D0%A3%D0%BF%D1%80%D0%B0%D0%B2%D0%BB%D1%8F%D1%8E%D1%89%D0%B8%D0%B5_%D1%81%D0%B8%D0%BC%D0%B2%D0%BE%D0%BB%D1%8B
	УпрСимволы_ASCII = "0,1,2,3,4,5,6,7,8,9,0B,0C,0E,0F,10,11,12,13,14,15,16,17,18,19,1A,1B,1C,1D,1E,1F,7F";
	УпрСимволы_ISO = "80,81,82,83,84,85,86,87,88,89,8A,8B,8С,8D,8E,8F,90,91,92,93,94,95,96,97,98,99,9A,9B,9C,9D,9E,9F";
	УпрСимволы_Unicode = "034F,2008,200B,200C,200D,200E,200F,2028,2029,202A,202B,202C,202D,202E,2060,2061,2063,2066,2067,2068,2069,206A,206B,206C,206D,206E,206F," +
		"FE00,FE01,FE02,FE03,FE04,FE05,FE06,FE07,FE08,FE09,FE0A,FE0B,FE0C,FE0D,FE0E,FE0F,FEFF,FFF9,FFFA,FFFB,FFFC,FFFD";
	
	УпрСимволы = СтрШаблон("%1,%2,%3", УпрСимволы_ASCII, УпрСимволы_ISO, УпрСимволы_Unicode);
	УпрСимволы = СтрРазделить(УпрСимволы, ",");
	УпрСимволы = Мап("Результат = Ох(Элемент)", УпрСимволы);
	УпрСимволы = Мап("Результат = Символ(Элемент)", УпрСимволы);
	УпрСимволы = ОбщегоНазначенияКлиентСервер.СвернутьМассив(УпрСимволы);
	
	Для ТекСимвол_Число = Ох("E0100") По Ох("E01EF") Цикл
		УпрСимволы.Добавить(Символ(ТекСимвол_Число));
	КонецЦикла;
	
	ЗаменитьТекстВТД(ТабДок, Символы.ВТаб, Символы.ПС);
	
	Для Каждого ТекСимвол_Число Из УпрСимволы Цикл
		ЗаменитьТекстВТД(ТабДок, ТекСимвол_Число, "");
	КонецЦикла;
	
КонецПроцедуры