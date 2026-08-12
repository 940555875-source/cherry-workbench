# amber的工作台 — Supabase 云端同步配置指南

按照以下步骤操作，约 **5 分钟** 即可完成配置，实现多设备数据同步。

---

## 第 1 步：注册 Supabase 账号

1. 打开浏览器访问 **[supabase.com](https://supabase.com)**
2. 点击右上角 **「Start your project」** 或 **「Sign Up」**
3. 选择用 **GitHub 账号登录**（最方便），或用邮箱注册
4. 完成验证后进入 Supabase 控制台

---

## 第 2 步：创建项目

1. 在控制台点击 **「New project」**（绿色按钮）
2. 填写项目信息：

| 字段 | 填写内容 |
|------|---------|
| **Name** | `amber-workbench`（任意名称） |
| **Database Password** | 设置一个密码（建议用 `生成随机密码` 按钮，把密码记下来） |
| **Region** | 选 **Northeast Asia (Tokyo)** 最快，或默认 |

3. 点击 **「Create new project」**，等待 1-2 分钟项目创建完成

---

## 第 3 步：获取 API 凭证

项目创建完成后，你会看到项目控制台。

1. 左侧菜单点击 **「Settings」**（齿轮图标）
2. 点击 **「API」**
3. 你会看到两个关键信息：

| 字段 | 说明 |
|------|------|
| **Project URL** | 类似 `https://xxxxxxxxxxxx.supabase.co` |
| **anon public key** | 类似 `eyJhbGciOiJIUzI1NiIs...` 开头的一长串 |

> 💡 **记下这两个值**，下一步要用。

---

## 第 4 步：执行建表 SQL

1. 左侧菜单点击 **「SQL Editor」**（数据库图标）
2. 点击 **「New query」**
3. 打开本项目的 `supabase-setup.sql` 文件，**复制全部内容**
4. 粘贴到 SQL Editor 中
5. 点击右下角 **「Run」** 按钮（或按 `Cmd+Enter`）
6. 看到 **"Success. No rows returned"** 即表示成功

> 🔍 验证：左侧菜单进入 **「Table Editor」**，应该能看到 `plans`、`events`、`checkins`、`notes`、`links` 五张表。

---

## 第 5 步：在工作台中填入凭证

1. 打开 **amber的工作台** 页面
2. 点击左侧底部的 **⚙ 设置** 按钮
3. 在弹出的设置框中填入：
   - **Supabase URL**：粘贴第 3 步的 Project URL
   - **Supabase Anon Key**：粘贴第 3 步的 anon public key
4. 点击 **「保存」**

---

## 第 6 步：验证连接

保存后，顶栏的同步状态药丸会自动检测：

| 状态 | 含义 |
|------|------|
| 🟢 **已同步** | 连接成功，数据正在云端同步 |
| ⚪ **仅本地** | 未配置或连接断开，点击「测试连接」诊断 |

如果显示「仅本地」，点击 **「测试连接」** 按钮查看具体原因。

---

## 常见问题

**Q: 连接失败怎么办？**
- 确认 URL 以 `https://` 开头，以 `.supabase.co` 结尾
- 确认 Key 完整复制，没有多余空格
- 确认已在 SQL Editor 中执行了建表脚本

**Q: 数据会泄露吗？**
- 当前使用匿名访问策略，同一项目的所有用户共享数据
- 如需私有化，可在 Supabase 中启用 Auth 并修改 RLS 策略

**Q: 不同设备的数据如何合并？**
- 采用「墓碑机制」：删除操作不会真正删除数据，而是打上删除标记
- 所有设备拉取数据时会自动过滤已删除的条目
- 保证了多设备数据的一致性
