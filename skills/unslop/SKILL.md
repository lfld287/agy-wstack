---
name: unslop
description: "删去文字中常见的 AI 写作痕迹。"
disable-model-invocation: true
---

# 清理 AI 写作痕迹

检查文字中是否出现下列模式，再改写。保留原意和所需语气。

规则编号是其他技能引用的固定 ID。删除规则后保留空号。

3. 删掉句尾没有新增事实的 “-ing” 短语，例如 “highlighting...” 或 “ensuring...”。
5. 删掉 “experts believe” 一类含糊归因。点名来源，或不写。
7. 避免 AI 惯用词，例如 additionally、crucial、delve、enhance、foster、landscape、pivotal、showcase、testament、underscore、vibrant。
8. 用 “is” 或 “has” 直接陈述，省去 “serves as”、“stands as”、“boasts”、“features”。
9. 避免 “not just X, but Y” 或「不仅 X，更 Y」一类句型。直接说要点。
10. 别硬凑三项。
11. 一个对象只用一个名字。需要时重复。
12. 只有 X 和 Y 真的处在同一个尺度上，才写 “from X to Y”。
13. 避免长破折号、短破折号和充当破折号的连字符，也别拿括号顶替。用句号或逗号。
14. 冒号用在列表或示例前。句中连接用其他标点或句法。
15. 别把所有专名和缩写都加粗。
16. 避免用冒号连接加粗的标签和重复该标签的正文，例如 “**Performance:** Performance improved...”。用句号收尾、有新增信息的加粗短句可以保留。
17. 英文标题用句首大写。
18. 去掉装饰性的表情符号。
19. 英文使用直引号。
20. 去掉聊天机器人套话，例如 “I hope this helps!”、“Let me know if...”。
22. 开头直接回答，省去称赞和表示赞同的套话。
23. 去掉赘词。“In order to” 改成 “to”。删掉 “it is important to note that”。
24. 最多留一处不确定限定，例如 “may”。
25. 避免泛泛收尾。写明具体计划或事实。
26. 避免拿抽象名词打比方，例如 substrate、wedge、vector、nexus、primitive、harness、surface、scaffolding、paradigm、ratchet、north star、flywheel。使用指向实际对象的词。
27. 写它实际做的事。明确机制或给出数字。删去能原封不动贴进另一个项目文档的句子。
28. 一句只讲一件事。读者得回头读的句子应拆开。
29. 用主动语态。除非行动者未知或无关紧要，否则写明由谁做。
30. 删掉副词，或换成更明确的动词。给出具体数字。
31. 选平实的词。用 “use”，少用 “utilize” 或 “leverage”。
32. 有直白说法时，避免隐喻、格言、拟人化的代码描写或比喻性的动词。
33. 写完整句子，保留英文冠词和动词。用文字写出箭头和缩写的含义。
