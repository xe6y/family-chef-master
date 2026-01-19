package utils

import "strings"

// ContainsIgnoreCase 判断字符串 s 是否包含 substr，忽略大小写
// s: 源字符串
// substr: 子字符串
// 返回: 是否包含
func ContainsIgnoreCase(s, substr string) bool {
	return strings.Contains(strings.ToLower(s), strings.ToLower(substr))
}
