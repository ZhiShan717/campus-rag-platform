package cn.campus.rag.user;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户表的 Mapper。空接口，但因为继承了 BaseMapper<User>，
 * 就自动拥有了 selectById / selectList / insert / updateById 等方法。
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {
}
