#!/usr/bin/env node

// A Dark Room 微信小程序构建脚本
const fs = require('fs');
const path = require('path');

// 获取命令行参数
const args = process.argv.slice(2);
const environment = args[0] || 'development';

console.log(`🚀 开始构建 A Dark Room 微信小程序 - 环境: ${environment}`);

// 验证环境参数
const validEnvironments = ['development', 'staging', 'production'];
if (!validEnvironments.includes(environment)) {
  console.error(`❌ 无效的环境参数: ${environment}`);
  console.error(`✅ 有效的环境: ${validEnvironments.join(', ')}`);
  process.exit(1);
}

// 配置文件路径
const configDir = path.join(__dirname, '../config');
const envExamplePath = path.join(configDir, 'env.example.js');
const envPath = path.join(configDir, 'env.js');

// 检查环境配置文件是否存在
if (!fs.existsSync(envPath)) {
  console.log('📋 环境配置文件不存在，从示例文件创建...');

  if (fs.existsSync(envExamplePath)) {
    // 复制示例文件
    const exampleContent = fs.readFileSync(envExamplePath, 'utf8');

    // 替换默认环境（确保兼容微信小程序）
    const updatedContent = exampleContent.replace(
      /const CURRENT_ENV = '[^']*'/,
      `const CURRENT_ENV = '${environment}'`
    );

    fs.writeFileSync(envPath, updatedContent);
    console.log('✅ 环境配置文件已创建');
    console.log('⚠️  请编辑 config/env.js 文件，配置正确的H5页面地址');
  } else {
    console.error('❌ 找不到环境配置示例文件');
    process.exit(1);
  }
} else {
  // 更新现有配置文件的环境设置
  let envContent = fs.readFileSync(envPath, 'utf8');

  // 更新当前环境（兼容微信小程序环境）
  envContent = envContent.replace(
    /const CURRENT_ENV = '[^']*'/,
    `const CURRENT_ENV = '${environment}'`
  );

  fs.writeFileSync(envPath, envContent);
  console.log(`✅ 环境配置已更新为: ${environment}`);
}

// 读取并验证配置
try {
  // 清除require缓存
  delete require.cache[require.resolve(envPath)];
  const config = require(envPath);

  console.log('📋 当前配置信息:');
  console.log(`   环境: ${config.environment}`);
  console.log(`   H5地址: ${config.h5Url}`);
  console.log(`   调试模式: ${config.debug}`);
  console.log(`   构建时间: ${config.buildTime}`);

  // 验证必要的配置项
  if (!config.h5Url || config.h5Url.includes('your-domain.com')) {
    console.warn('⚠️  警告: H5页面地址仍使用示例值，请更新为实际地址');
  }

  if (!config.appId || config.appId.includes('your-')) {
    console.warn('⚠️  警告: 微信小程序AppID仍使用示例值，请更新为实际AppID');
  }

} catch (error) {
  console.error('❌ 配置文件验证失败:', error.message);
  process.exit(1);
}

console.log('🎉 构建完成！');
console.log('📝 下一步:');
console.log('   1. 在微信开发者工具中打开项目');
console.log('   2. 检查配置是否正确');
console.log('   3. 进行测试和调试');